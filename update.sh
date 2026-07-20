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

echo "Homebrew bijwerken..."
brew update

echo "Pakketten en apps uit de Brewfile bijwerken..."
caffeinate -i brew bundle upgrade --file="$DOTFILES_DIR/Brewfile"

echo "Oude Homebrew-downloads en versies opruimen..."
brew cleanup

echo "Homebrew-update voltooid."
