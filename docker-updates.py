#!/usr/bin/env python3
"""Review staged Docker image updates and recreate selected containers safely."""

import json
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent


def run(*args, capture=True):
    return subprocess.run(args, check=True, text=True,
                          stdout=subprocess.PIPE if capture else None)


def docker_json(*args):
    return json.loads(run("docker", *args).stdout)


def containers():
    ids = run("docker", "ps", "-aq").stdout.split()
    if not ids:
        return []
    return [item for item in docker_json("inspect", *ids)
            if item["Name"] != "/portainer-before-update"]


def image_info(ref):
    try:
        return docker_json("image", "inspect", ref)[0]
    except (subprocess.CalledProcessError, IndexError, ValueError):
        return None


def describe(container):
    config = container["Config"]
    labels = config.get("Labels") or {}
    ref = config["Image"]
    running_id = container["Image"]
    tagged = image_info(ref)
    running = image_info(running_id)
    project = labels.get("com.docker.compose.project", "")
    service = labels.get("com.docker.compose.service", "")
    files = labels.get("com.docker.compose.project.config_files", "")
    workdir = labels.get("com.docker.compose.project.working_dir", "")
    if not tagged:
        state = "unknown"
    elif tagged["Id"] != running_id:
        state = "update"
    elif not (running or {}).get("RepoDigests"):
        state = "local/unknown"
    else:
        state = "current"
    old_labels = ((running or {}).get("Config") or {}).get("Labels") or {}
    new_labels = ((tagged or {}).get("Config") or {}).get("Labels") or {}
    return {
        "name": container["Name"].lstrip("/"), "ref": ref,
        "state": state, "project": project, "service": service,
        "files": files, "workdir": workdir,
        "old_id": running_id, "new_id": (tagged or {}).get("Id", ""),
        "old_version": old_labels.get("org.opencontainers.image.version", ""),
        "new_version": new_labels.get("org.opencontainers.image.version", ""),
        "source": new_labels.get("org.opencontainers.image.source", ""),
    }


def snapshot():
    return sorted((describe(item) for item in containers()), key=lambda item: item["name"])


def show(items):
    print("\nDocker containers (vergelijking met lokaal opgehaalde images):\n")
    for index, item in enumerate(items, 1):
        print(f"  {index:2}) {item['name']:<26} {item['state']:<13} {item['ref']}")
    print("\n'current' betekent actueel ten opzichte van de lokaal opgehaalde image.")
    print("Gebruik eerst 'Check for updates' om de registry op te vragen.")
    print("'local/unknown' en 'unknown' worden nooit automatisch bijgewerkt.\n")


def confirm(prompt):
    return input(f"{prompt} [y/N] ").strip().lower() in ("y", "yes")


def refresh(only_ref=None):
    items = snapshot()
    refs = sorted({item["ref"] for item in items if item["state"] != "local/unknown"
                   and "@sha256:" not in item["ref"]
                   and (only_ref is None or item["ref"] == only_ref)})
    if not refs:
        print("Deze image is lokaal gebouwd of niet eenduidig te controleren.")
        return None
    print(f"Dit haalt {len(refs)} image(s) op; draaiende containers veranderen niet.")
    if not confirm("Nu de registries controleren?"):
        return None
    failed = []
    for index, ref in enumerate(refs, 1):
        print(f"\n[{index}/{len(refs)}] {ref}", flush=True)
        if subprocess.run(("docker", "pull", ref)).returncode != 0:
            failed.append(ref)
    if failed:
        print("\nNiet gecontroleerd wegens pull-fout: " + ", ".join(failed))
    items = snapshot()
    for item in items:
        if item["ref"] in failed:
            item["state"] = "unknown"
    show(items)
    return items


def compose_command(item):
    workdir = Path(item["workdir"])
    files = [Path(name) for name in item["files"].split(",") if name]
    if not item["project"] or not item["service"] or not workdir.is_dir() or not files:
        raise ValueError("Compose-projectgegevens ontbreken")
    if any(not name.is_file() for name in files):
        raise ValueError("Compose-bestand ontbreekt; open deze stack in Portainer")
    command = ["docker", "compose", "--project-directory", str(workdir),
               "-p", item["project"]]
    for name in files:
        command += ["-f", str(name)]
    return command


def print_detail(item):
    print(f"\n{item['name']} ({item['project'] or 'losse container'})")
    print(f"Image: {item['ref']}")
    print(f"Draaiend: {item['old_id'][:19]}  {item['old_version']}")
    print(f"Opgehaald: {item['new_id'][:19]}  {item['new_version']}")
    if item["source"]:
        print(f"Bron/release notes: {item['source']}")
    print("Controleer zelf de release notes; image-digests beschrijven geen functionele wijzigingen.")


def update(item):
    print_detail(item)
    if item["name"] == "portainer" and item["ref"] == "portainer/portainer-ce:latest":
        print("Portainer wordt als losse container opnieuw aangemaakt; de data blijft op de server.")
        command = [str(ROOT / "server-scripts/update-portainer.sh")]
    else:
        try:
            command = compose_command(item)
        except ValueError as error:
            print(f"Overgeslagen: {error}.")
            return False
        command += ["up", "-d", "--no-deps", "--no-build", "--pull", "never", item["service"]]
    print("Actie: " + " ".join(command))
    try:
        run(*command, capture=False)
        after = next((entry for entry in snapshot() if entry["name"] == item["name"]), None)
        if after and after["old_id"] == item["new_id"]:
            print(f"Klaar: {item['name']} draait met de opgehaalde image.")
            return True
        print(f"Controle nodig: {item['name']} draait niet met de verwachte image.")
    except subprocess.CalledProcessError as error:
        print(f"Update mislukt (exit {error.returncode}); controleer de container en logs.")
    return False


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in ("list", "check", "one", "all"):
        raise SystemExit("Gebruik: docker-updates.py list|check|one|all")
    action = sys.argv[1]
    if action == "list":
        show(snapshot())
        return
    chosen_name = None
    only_ref = None
    if action == "one":
        initial = snapshot()
        show(initial)
        choice = input("Nummer van container om te controleren (Enter = terug): ").strip()
        if not choice.isdigit() or not 1 <= int(choice) <= len(initial):
            return
        chosen = initial[int(choice) - 1]
        chosen_name, only_ref = chosen["name"], chosen["ref"]
    items = refresh(only_ref)
    if items is None:
        return
    pending = [item for item in items if item["state"] == "update"]
    if not pending or action == "check":
        return
    if action == "one":
        item = next(entry for entry in items if entry["name"] == chosen_name)
        if item["state"] != "update":
            print("Voor deze container is geen bevestigde image-update beschikbaar.")
            return
        print_detail(item)
        if confirm(f"Alleen {item['name']} nu bijwerken?"):
            update(item)
    else:
        print("\nTe wijzigen containers: " + ", ".join(item["name"] for item in pending))
        print("Portainer wordt als laatste verwerkt. Onbekende en lokale images worden overgeslagen.")
        if not confirm(f"Alle {len(pending)} bevestigde updates toepassen?"):
            return
        failed = []
        for item in sorted(pending, key=lambda value: value["name"] == "portainer"):
            if not update(item):
                failed.append(item["name"])
        if failed:
            print("\nNiet gelukt of overgeslagen: " + ", ".join(failed))


if __name__ == "__main__":
    try:
        main()
    except (subprocess.CalledProcessError, KeyboardInterrupt) as error:
        raise SystemExit(f"Afgebroken: {error}")
