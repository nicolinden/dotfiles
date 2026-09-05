#!/usr/bin/env bash

# Apply dotfile changes after `git pull` without reinstalling packages.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

configure_homebrew_for_current_shell() {
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

if [[ "$(uname -s)" == "Darwin" ]]; then
  configure_homebrew_for_current_shell
fi

echo "Dotfiles opnieuw koppelen..."
stow --restow --dir="$DOTFILES_DIR" --target="$HOME" home

if [[ "$(uname -s)" == "Darwin" ]]; then
  stow --restow --dir="$DOTFILES_DIR" --target="$HOME" macos
  "$DOTFILES_DIR/configure-noki-ssh.sh"

  if command -v aerospace >/dev/null 2>&1; then
    echo "AeroSpace herladen..."
    aerospace reload-config
  fi

  SKHD_APP_BIN="/Applications/skhd.app/Contents/MacOS/skhd"
  if [[ -x "$SKHD_APP_BIN" ]]; then
    echo "Globale sneltoetsen herladen..."
    "$SKHD_APP_BIN" --install-service 2>/dev/null || true
    "$SKHD_APP_BIN" --restart-service
  fi

  if command -v sketchybar >/dev/null 2>&1; then
    echo "SketchyBar herladen..."
    sketchybar --reload
  fi

  # Borders reads ~/.config/borders/bordersrc at startup. The Homebrew service
  # keeps it alive after this script exits and also starts it at the next login.
  if command -v brew >/dev/null 2>&1 && brew list borders >/dev/null 2>&1; then
    echo "Vensterborder herladen..."
    brew services restart borders
  fi
fi

# Existing tmux servers keep their old configuration until it is sourced.
if command -v tmux >/dev/null 2>&1 && tmux has-session 2>/dev/null; then
  echo "tmux herladen..."
  tmux source-file "$HOME/.config/tmux/tmux.conf"
fi

echo
echo "Klaar. Open een nieuw terminalvenster voor wijzigingen in .zshrc."
