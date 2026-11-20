"""Compare local app bundles and Homebrew receipts with every install profile."""
import json
import os
import pathlib
import plistlib
import re
import sys
import subprocess


def normalize(name):
    return re.sub(r"[^a-z0-9]", "", re.sub(r"\.app$", "", name.lower()).replace(" creator studio", ""))


def read_json(path):
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError) as error:
        warnings.append(f"Could not read {path}: {error}")
        return {}


def app_names(receipt):
    for artifact in receipt.get("uninstall_artifacts", []):
        app = artifact.get("app")
        if not app:
            continue
        name = app[0] if isinstance(app, list) else app
        if isinstance(app, list) and len(app) > 1 and isinstance(app[1], dict):
            name = app[1].get("target", name)
        yield pathlib.Path(name).name


repo, prefix = map(pathlib.Path, sys.argv[1:3])
warnings = []
declared = {"brew": set(), "cask": set(), "mas": set()}
for file in repo.glob("Brewfile*"):
    for kind, name in re.findall(r'^(brew|cask|mas) "([^"]+)"', file.read_text(), re.M):
        declared[kind].add(name.split("/")[-1] if kind != "mas" else name)
system_casks = re.search(r'SYSTEM_CASKS=\((.*?)\)', (repo / "system-apps.conf").read_text(), re.S)
if system_casks:
    declared["cask"].update(re.findall(r'"([^"]+)"', system_casks.group(1)))
known_apps = {normalize(name) for names in declared.values() for name in names}
known_apps.update(map(normalize, ["Razer Synapse", "Razer Synapse Installer"]))
# Different distribution names for the same declared applications.
aliases = {
    "docker-desktop": ["Docker"], "tailscale-app": ["Tailscale"],
    "codex-app": ["Codex"], "displaylink": ["DisplayLink Manager"],
    "wacom-tablet": ["Wacom Center", "Wacom Tablet Utility", "Wacom Display Settings", "WacomTabletDriver"],
    "sf-symbols": ["SF Symbols", "SF Symbols Beta"],
}
for token, names in aliases.items():
    if token in declared["cask"]:
        known_apps.update(map(normalize, names))

extra_casks = []
all_cask_apps = {}
for receipt_path in sorted((prefix / "Caskroom").glob("*/.metadata/INSTALL_RECEIPT.json")):
    token = receipt_path.parents[1].name
    names = list(app_names(read_json(receipt_path)))
    for name in names:
        all_cask_apps[normalize(name)] = token
    if token in declared["cask"]:
        known_apps.update(map(normalize, names))
    else:
        extra_casks.append(token)

extra_formulae = set()
for receipt_path in (prefix / "Cellar").glob("*/*/INSTALL_RECEIPT.json"):
    receipt = read_json(receipt_path)
    token = receipt_path.parents[1].name
    if receipt.get("installed_on_request") and token not in declared["brew"]:
        extra_formulae.add(token)

extra_apps = []
seen = set()
for root in [pathlib.Path("/Applications"), pathlib.Path.home() / "Applications"]:
    # Prune app bundles: do not inventory their embedded helpers as separate apps.
    for directory, dirs, _files in os.walk(root, onerror=lambda err: warnings.append(str(err))):
        apps = [name for name in dirs if name.endswith(".app")]
        dirs[:] = [name for name in dirs if not name.endswith(".app")]
        for name in apps:
            app = pathlib.Path(directory) / name
            normalized = normalize(name)
            info_path = app / "Contents/Info.plist"
            if not info_path.exists():
                info_path = app / "WrappedBundle/Info.plist"
            try:
                with info_path.open("rb") as stream:
                    info = plistlib.load(stream)
            except (OSError, ValueError, plistlib.InvalidFileException):
                info = {}
            bundle_id = info.get("CFBundleIdentifier", "")
            if bundle_id.startswith("com.apple.") or normalized in known_apps:
                continue
            if normalized in all_cask_apps:
                # The cask is already listed below; do not duplicate its app here.
                continue
            if str(app) not in seen:
                extra_apps.append(str(app))
                seen.add(str(app))

def manage_entries(entries):
    if not entries:
        return 0
    print("\nChoose numbers to remove (for example 1 3), b to go back, or q to quit.")
    try:
        selection = input("Selection: ").strip()
    except EOFError:
        return 0
    if selection.lower() == "q":
        return 21
    if selection.lower() == "b" or not selection:
        return 20
    choices = re.split(r"[ ,]+", selection)
    if any(not re.fullmatch(r"[1-9][0-9]*", choice) or int(choice) > len(entries) for choice in choices):
        print("Invalid selection. Nothing was removed.")
        return 1
    selected = [entries[index] for index in dict.fromkeys(int(choice) - 1 for choice in choices)]
    print("\nRemove these selected items:")
    for kind, item in selected:
        print(f"  - {item} ({kind})")
    print("Homebrew packages are uninstalled without --zap. Other apps go to the Trash.")
    print("Preferences and documents are preserved; system installers may have separate uninstallers.")
    try:
        confirmed = input("Remove the selected items? [y/N] ").strip().lower() in ("y", "yes")
    except EOFError:
        confirmed = False
    if not confirmed:
        print("Nothing was removed.")
        return 20
    failures = 0
    for kind, item in selected:
        try:
            if kind in ("cask", "formula"):
                if kind == "formula" and item in ("borders", "sketchybar", "skhd"):
                    subprocess.run(["brew", "services", "stop", item], check=True)
                subprocess.run(["brew", "uninstall", "--" + kind, item], check=True)
            else:
                app = pathlib.Path(item)
                allowed_roots = [pathlib.Path("/Applications"), pathlib.Path.home() / "Applications"]
                if app.is_symlink() or not app.is_dir() or app.suffix != ".app" or not any(
                        root.resolve() in app.resolve().parents for root in allowed_roots):
                    raise ValueError("The app path changed or is not an ordinary app bundle")
                subprocess.run(["osascript", "-e", "on run argv", "-e",
                                'tell application "Finder" to delete (POSIX file (item 1 of argv) as alias)',
                                "-e", "end run", str(app)], check=True)
            print("Removed: " + item)
        except (OSError, ValueError, subprocess.CalledProcessError) as error:
            failures += 1
            print(f"Could not remove {item}: {error}")
    print(f"\n{len(selected) - failures} item(s) removed; {failures} failed.")
    return 1 if failures else 0


interactive = "--manage" in sys.argv[3:]
entries = []
for title, kind, items in [
    ("Apps outside every install profile", "app", sorted(extra_apps)),
    ("Homebrew apps/casks outside every install profile", "cask", extra_casks),
    ("Explicitly installed Homebrew tools outside every install profile (dependencies excluded)", "formula", sorted(extra_formulae)),
]:
    print(f"\n{title}:")
    for item in items:
        entries.append((kind, item))
        marker = f"{len(entries)})" if interactive else "-"
        print(f"  {marker} {item}")
    if not items:
        print("  None found.")
print("\nAll profiles count as managed, even optional profiles. Built-in Apple apps are omitted.")
print("This is an installation-list comparison, not a measurement of app usage.")
for warning in warnings:
    print("Warning: " + warning)
if interactive:
    sys.exit(manage_entries(entries))
print("Nothing was changed.")
