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
  echo "Dit script is uitsluitend bedoeld voor macOS."
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  configure_homebrew_for_current_shell
fi

if ! command -v mas >/dev/null 2>&1; then
  echo "Mac App Store-tooling ontbreekt. Voer eerst ./bootstrap.sh uit."
  exit 1
fi

if ! mas account >/dev/null 2>&1; then
  echo "Log eerst in bij de Mac App Store en voer dit script daarna opnieuw uit."
  exit 1
fi

echo "Office-apps uit de Mac App Store installeren..."
if ! caffeinate -i brew bundle install --file="$DOTFILES_DIR/Brewfile.office.mas"; then
  echo
  echo "Een of meer Office-apps konden niet worden geïnstalleerd."
  echo "Controleer in de Mac App Store of ze aan je Apple-account zijn gekoppeld."
  exit 1
fi

echo "Office-installatie voltooid. Log in met je Microsoft-account in de gewenste apps."
