#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

configure_homebrew_for_current_shell() {
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Dit updatescript is uitsluitend bedoeld voor macOS."
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  configure_homebrew_for_current_shell
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is niet geïnstalleerd."
  exit 1
fi

echo "Homebrew bijwerken..."
brew update

echo "Alle geïnstalleerde Homebrew-pakketten en casks bijwerken..."
caffeinate -i brew upgrade

if command -v mas >/dev/null 2>&1; then
  echo "Mac App Store-apps bijwerken..."
  mas upgrade || echo "Mac App Store-updates overgeslagen; controleer je aanmelding."
fi

echo "Oude Homebrew-downloads en versies opruimen..."
brew cleanup

echo "Dotfiles opnieuw toepassen..."
"$DOTFILES_DIR/reload.sh"

echo "Homebrew-update voltooid."
