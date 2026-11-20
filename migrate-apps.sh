#!/usr/bin/env bash

# Reinstall Homebrew-managed apps so receipts and CLI links follow the new path.
# Move other top-level app bundles without replacing existing destinations.
set -euo pipefail
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/menu-ui.sh"
[[ "$(uname -s)" == Darwin ]] || { echo "This script is for macOS only."; exit 1; }
case "${1:-}" in ""|--dry-run) ;; *) echo "Usage: ./migrate-apps.sh [--dry-run]"; exit 1 ;; esac
if ! command -v brew >/dev/null 2>&1; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi
plan="$(mktemp)"
trap 'rm -f "$plan"' EXIT
python3 - "$(brew --caskroom)" >"$plan" <<'PY'
import json, os, pathlib, sys
home_apps = pathlib.Path.home() / 'Applications'
managed = set()
retired = {'aerospace', 'proton-pass'}
for config_path in sorted(pathlib.Path(sys.argv[1]).glob('*/.metadata/config.json')):
    config = json.loads(config_path.read_text())
    appdir = next((config.get(k, {}).get('appdir') for k in ('explicit', 'env', 'default')
                   if config.get(k, {}).get('appdir')), '/Applications')
    if pathlib.Path(os.path.expanduser(appdir)) != home_apps:
        continue
    receipt = json.loads((config_path.parent / 'INSTALL_RECEIPT.json').read_text())
    names = []
    for artifact in receipt.get('uninstall_artifacts', []):
        if 'app' not in artifact:
            continue
        app = artifact['app']
        name = pathlib.Path(app[0] if isinstance(app, list) else app).name
        if isinstance(app, list) and len(app) > 1 and isinstance(app[1], dict):
            name = pathlib.Path(app[1].get('target', name)).name
        names.append(name)
    managed.update(names)
    token = config_path.parents[1].name
    if not any((home_apps / n).exists() for n in names):
        continue
    if token in retired:
        print('skip|' + token + '|Use the retired-app cleanup instead')
    elif any(os.path.lexists('/Applications/' + n) for n in names):
        print('skip|' + token + '|Destination already exists; resolve duplicate copies first')
    else:
        print('cask|' + token + '|Reinstall in /Applications and update Homebrew receipts')
for app in sorted(home_apps.glob('*.app')):
    if app.name in managed:
        continue
    if app.is_symlink() or os.path.lexists('/Applications/' + app.name):
        print('skip|' + str(app) + '|Symlink or existing destination; left untouched')
    else:
        print('move|' + str(app) + '|Move to /Applications')
PY

if [[ ! -s "$plan" ]]; then
  echo "No home-folder apps need migration."
  exit 0
fi
cat "$plan"
[[ "${1:-}" != --dry-run ]] || exit 0
echo "Close the listed apps first. Homebrew reinstalls may download newer versions."
if ! confirm_action "Apply this migration (existing destinations are skipped)?"; then
  exit "$MENU_CANCELLED"
fi
failures=0
while IFS='|' read -r kind item description; do
  case "$kind" in
    cask)
      if ! HOMEBREW_CASK_OPTS="--appdir=/Applications" caffeinate -i \
        brew reinstall --cask --appdir=/Applications "$item"; then
        echo "Migration failed: $item. Rerun after resolving the Homebrew error."
        failures=$((failures + 1))
      fi
      ;;
    move)
      destination="/Applications/$(basename "$item")"
      if [[ -e "$destination" || -L "$destination" ]]; then
        echo "Skipped existing destination: $destination"
        failures=$((failures + 1))
        continue
      fi
      if [[ -w /Applications ]]; then
        mv -n "$item" "$destination" || failures=$((failures + 1))
      else
        sudo mv -n "$item" "$destination" || failures=$((failures + 1))
      fi
      ;;
    skip) echo "Skipped: $item ($description)"; failures=$((failures + 1)) ;;
  esac
done <"$plan"
if (( failures > 0 )); then
  echo "$failures migration item(s) need attention; no existing destination was overwritten."
  exit 1
fi
echo "Apps migrated to /Applications."
