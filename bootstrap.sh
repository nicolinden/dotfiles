#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is nog niet geïnstalleerd."
  echo "Installeer Homebrew eerst via https://brew.sh"
  exit 1
fi

echo "Homebrew-pakketten installeren..."
brew bundle install --file="$DOTFILES_DIR/Brewfile"

echo "Dotfiles koppelen..."
stow --dir="$DOTFILES_DIR" --target="$HOME" --verbose home

echo "Setup voltooid."
