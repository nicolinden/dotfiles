#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Dit updatescript is uitsluitend bedoeld voor macOS."
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is niet geïnstalleerd."
  exit 1
fi

echo "Beheerdersrechten voorbereiden..."
sudo -v

# Houd sudo uitsluitend tijdens deze update geldig
while true; do
  sudo -n true
  sleep 60
done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!

trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT INT TERM

echo "Homebrew bijwerken..."
brew update

echo "Pakketten en apps uit de Brewfile bijwerken..."
caffeinate -i brew bundle upgrade --file="$DOTFILES_DIR/Brewfile"

echo "Oude Homebrew-downloads en versies opruimen..."
brew cleanup

echo "Homebrew-update voltooid."
