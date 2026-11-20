#!/usr/bin/env bash

# Explicit, repeatable migration for Macs that used the old window manager.
set -euo pipefail
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/menu-ui.sh"
[[ "$(uname -s)" == Darwin ]] || { echo "This script is for macOS only."; exit 1; }
if ! command -v brew >/dev/null 2>&1; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

formulae=(borders sketchybar switchaudio-osx skhd)
casks=(aerospace font-sketchybar-app-font skhd-zig proton-pass)
paths=(
  .aerospace.toml .config/aerospace .config/borders .config/sketchybar .config/skhd
  .local/bin/toggle-aerospace .local/bin/aerospace-refresh-sketchybar
  .local/bin/aerospace-service-mode .local/bin/toggle-sketchybar-menu
  .config/raycast/script-commands/toggle-aerospace.sh
)
echo "Remove installed copies of: ${formulae[*]} ${casks[*]}"
echo "Stop their services and archive the old configuration below:"
for path in "${paths[@]}"; do
  [[ ! -e "$HOME/$path" && ! -L "$HOME/$path" ]] || printf '  - ~/%s\n' "$path"
done
echo "App preferences and account data are preserved; no Homebrew --zap is used."
if ! confirm_action "Clean up these retired components?"; then
  exit "$MENU_CANCELLED"
fi

if command -v skhd >/dev/null 2>&1; then
  skhd --uninstall-service || echo "No skhd service could be unregistered."
fi
for name in borders sketchybar skhd; do
  if brew list --formula "$name" >/dev/null 2>&1; then
    brew services stop "$name"
  fi
done
pkill -x AeroSpace || true
for name in "${casks[@]}"; do
  if brew list --cask "$name" >/dev/null 2>&1; then
    brew uninstall --cask "$name"
  fi
done
for name in "${formulae[@]}"; do
  if brew list --formula "$name" >/dev/null 2>&1; then
    brew uninstall --formula "$name"
  fi
done

backup_dir=""
for path in "${paths[@]}"; do
  [[ -e "$HOME/$path" || -L "$HOME/$path" ]] || continue
  if [[ -z "$backup_dir" ]]; then
    mkdir -p "$HOME/.local/share/dotfiles-backups"
    backup_dir="$(mktemp -d "$HOME/.local/share/dotfiles-backups/retired.XXXXXX")"
  fi
  mkdir -p "$backup_dir/$(dirname "$path")"
  mv "$HOME/$path" "$backup_dir/$path"
done
[[ -z "$backup_dir" ]] || echo "Old configuration archived in: $backup_dir"
echo "Retired components removed. Remove any old Toggle AeroSpace hotkey in Raycast Settings."
