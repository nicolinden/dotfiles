#!/usr/bin/env bash

# Upgrade only already-installed Homebrew packages declared in this repository.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/menu-ui.sh"
BREWFILES=(Brewfile Brewfile.dev Brewfile.personal)
formulae=()
casks=()

configure_homebrew_for_current_shell() {
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script is for macOS only."
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  configure_homebrew_for_current_shell
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is missing."
  exit 1
fi

for brewfile in "${BREWFILES[@]}"; do
  while IFS='|' read -r kind name; do
    [[ -n "$name" ]] || continue
    if [[ "$kind" == "brew" ]] && brew list --formula "$name" >/dev/null 2>&1; then
      formulae+=("$name")
    elif [[ "$kind" == "cask" ]]; then
      # Brewfile casks can be written as tap/name; `brew list` uses name.
      name="${name##*/}"
      if brew list --cask "$name" >/dev/null 2>&1; then
        casks+=("$name")
      fi
    fi
  done < <(sed -nE 's/^(brew|cask) "([^"]+)".*/\1|\2/p' "$DOTFILES_DIR/$brewfile")
done

echo "Updating Homebrew package definitions..."
brew update

if (( ${#formulae[@]} > 0 )); then
  echo "Updating ${#formulae[@]} managed command-line package(s)..."
  brew upgrade "${formulae[@]}"
fi

if (( ${#casks[@]} > 0 )); then
  echo "Updating ${#casks[@]} managed app(s)..."
  brew upgrade --cask "${casks[@]}"
fi

echo "Cleaning up old Homebrew downloads and versions..."
brew cleanup

"$DOTFILES_DIR/reload.sh"
refresh_sketchybar_updates
echo "Managed Homebrew packages are up to date."
