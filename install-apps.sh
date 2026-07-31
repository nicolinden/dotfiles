#!/usr/bin/env bash

# Install optional macOS app profiles after bootstrap, or on an existing Mac.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/menu-ui.sh"
source "$DOTFILES_DIR/system-apps.conf"

configure_homebrew_for_current_shell() {
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_brewfile() {
  local file="$1"
  local label="$2"

  print_menu_header "Confirm $label"
  echo "This will install or update:"
  show_brewfile_plan "$DOTFILES_DIR/$file"

  if ! confirm_action "Install $label?"; then
    echo "Cancelled."
    return "$MENU_CANCELLED"
  fi

  echo
  echo "Installing: $label"
  HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications" \
    caffeinate -i brew bundle install --file="$DOTFILES_DIR/$file"
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script is for macOS only."
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  configure_homebrew_for_current_shell
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is missing. Run ./bootstrap.sh first."
  exit 1
fi

mkdir -p "$HOME/Applications"

print_menu_header "Optional macOS app profiles"
echo "  1) Development apps"
echo "  2) Personal apps"
echo "  3) Personal Mac App Store apps"
echo "  4) Office and iWork"
echo "  5) System apps"
echo "  6) Remove optional apps"
echo "  b) Back"
echo
read -r -p "Choose an option: " selection

case "$selection" in
  1)
    if install_brewfile "Brewfile.dev" "development apps"; then :; else exit "$?"; fi
    ;;
  2)
    if install_brewfile "Brewfile.personal" "personal apps"; then :; else exit "$?"; fi
    ;;
  3)
    if "$DOTFILES_DIR/install-mac-apps.sh"; then :; else exit "$?"; fi
    ;;
  4)
    if "$DOTFILES_DIR/office-installer.sh"; then :; else exit "$?"; fi
    ;;
  5)
    if "$DOTFILES_DIR/install-system-apps.sh"; then :; else exit "$?"; fi
    ;;
  6) "$DOTFILES_DIR/uninstall-apps.sh" ;;
  b|B|"") exit 0 ;;
  *) echo "Invalid choice." ;;
esac

wait_for_menu_return
