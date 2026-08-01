#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/menu-ui.sh"

configure_homebrew_for_current_shell() {
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
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

if ! command -v mas >/dev/null 2>&1; then
  configure_homebrew_for_current_shell
fi

if ! command -v mas >/dev/null 2>&1; then
  echo "Mac App Store-tooling ontbreekt. Voer eerst ./bootstrap.sh uit."
  exit 1
fi

print_menu_header "Mac App Store apps"
echo "This will install or update:"
show_mas_plan "$DOTFILES_DIR/Brewfile.mas"
if ! confirm_action "Install these Mac App Store apps?"; then
  echo "Cancelled."
  exit "$MENU_CANCELLED"
fi

echo
echo "Mac App Store-apps installeren..."
echo "Zorg dat je in de Mac App Store bent ingelogd."
start_sudo_keepalive

if ! run_with_progress "Mac App Store-apps installeren" \
  caffeinate -i brew bundle install --file="$DOTFILES_DIR/Brewfile.mas"; then
  echo
  echo "Een of meer apps konden niet worden geïnstalleerd."
  echo "Controleer je App Store-aanmelding en of betaalde apps zijn gekocht of geclaimd."
  exit 1
fi

echo "Mac App Store-apps zijn verwerkt."
