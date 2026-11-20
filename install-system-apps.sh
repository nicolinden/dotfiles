#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/menu-ui.sh"
source "$DOTFILES_DIR/system-apps.conf"

# Voeg hier apps toe die systeemcomponenten installeren of sudo nodig hebben.
# Houd de volgorde van SYSTEM_CASKS en SYSTEM_LABELS gelijk.
configure_homebrew_for_current_shell() {
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    echo "Homebrew is niet gevonden. Voer eerst ./bootstrap.sh uit."
    exit 1
  fi
}

start_sudo_keepalive() {
  echo "Beheerdersrechten voorbereiden (eenmalig)..."
  sudo -v

  while sudo -n true; do
    sleep 60
  done 2>/dev/null &
  SUDO_KEEPALIVE_PID=$!

  trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT INT TERM
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Dit script is uitsluitend bedoeld voor macOS."
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  configure_homebrew_for_current_shell
fi

echo "System apps are now available under Install apps → Work apps."
echo "Tailscale is part of Basis and is installed through the Mac App Store."
