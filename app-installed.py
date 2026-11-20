"""Recognize manually installed app bundles as well as Homebrew installations."""
import os
import pathlib
import plistlib
import re
import sys


def normalized(name):
    return re.sub(r"[^a-z0-9]", "", name.lower().replace(".app", "").replace(" creator studio", ""))


token = sys.argv[1]
aliases = {
    "codex-app": ["Codex"], "chatgpt": ["ChatGPT", "Codex"], "docker-desktop": ["Docker"],
    "tailscale-app": ["Tailscale"], "displaylink": ["DisplayLink Manager"],
    "wacom-tablet": ["Wacom Center", "Wacom Desktop Center"],
    "sf-symbols": ["SF Symbols", "SF Symbols Beta"],
}
names = {normalized(name) for name in aliases.get(token, [token])}
roots = list(map(pathlib.Path, sys.argv[2:])) or [pathlib.Path("/Applications"), pathlib.Path.home() / "Applications"]
for root in roots:
    for directory, dirs, _files in os.walk(root):
        apps = [name for name in dirs if name.endswith(".app")]
        dirs[:] = [name for name in dirs if not name.endswith(".app")]
        for name in apps:
            if normalized(name) not in names:
                continue
            if token == "chatgpt":
                # Classic may also be named ChatGPT.app. The current Codex-based
                # desktop app uses com.openai.codex; do not mistake Classic for it.
                try:
                    with (pathlib.Path(directory) / name / "Contents/Info.plist").open("rb") as stream:
                        if plistlib.load(stream).get("CFBundleIdentifier") != "com.openai.codex":
                            continue
                except (OSError, ValueError, plistlib.InvalidFileException):
                    continue
            sys.exit(0)
sys.exit(1)
