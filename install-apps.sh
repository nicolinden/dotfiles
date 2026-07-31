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
    return
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
printf '     %s\n' "$(brewfile_summary "$DOTFILES_DIR/Brewfile.dev")"
echo "  2) Personal apps"
printf '     %s\n' "$(brewfile_summary "$DOTFILES_DIR/Brewfile.personal")"
echo "  3) Personal Mac App Store apps"
printf '     %s\n' "$(mas_brewfile_summary "$DOTFILES_DIR/Brewfile.mas")"
echo "  4) Office and iWork"
printf '     %s\n' "$(mas_brewfile_summary "$DOTFILES_DIR/Brewfile.office.mas")"
echo "  5) System apps"
printf '     %s\n' "$(system_apps_summary)"
echo "  6) Remove optional apps"
echo "  b) Back"
echo
read -r -p "Choose an option: " selection

case "$selection" in
  1) install_brewfile "Brewfile.dev" "development apps" ;;
  2) install_brewfile "Brewfile.personal" "personal apps" ;;
  3) "$DOTFILES_DIR/install-mac-apps.sh" ;;
  4) "$DOTFILES_DIR/office-installer.sh" ;;
  5) "$DOTFILES_DIR/install-system-apps.sh" ;;
  6) "$DOTFILES_DIR/uninstall-apps.sh" ;;
  b|B|"") exit 0 ;;
  *) echo "Invalid choice." ;;
esac

wait_for_menu_return
