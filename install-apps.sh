#!/usr/bin/env bash

# Install the configured macOS app collection, Office apps, or Citrix automation.
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

install_configured_apps() {
  print_menu_header "Confirm app installation"
  echo "This installs all configured non-Office apps:"
  echo
  echo "Homebrew apps and tools:"
  show_brewfile_plan "$DOTFILES_DIR/Brewfile"
  show_brewfile_plan "$DOTFILES_DIR/Brewfile.dev"
  show_brewfile_plan "$DOTFILES_DIR/Brewfile.personal"
  echo "Mac App Store apps:"
  show_mas_plan "$DOTFILES_DIR/Brewfile.mas"
  echo "System apps:"
  printf '  - %s\n' "${SYSTEM_LABELS[@]}"

  if ! confirm_action "Install all configured apps?"; then
    echo "Cancelled."
    return "$MENU_CANCELLED"
  fi

  export DOTFILES_ASSUME_YES=1
  export DOTFILES_INSTALL_ALL=1
  mkdir -p "$HOME/Applications"
  env HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications" \
    caffeinate -i brew bundle install --file="$DOTFILES_DIR/Brewfile"
  env HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications" \
    caffeinate -i brew bundle install --file="$DOTFILES_DIR/Brewfile.dev"
  env HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications" \
    caffeinate -i brew bundle install --file="$DOTFILES_DIR/Brewfile.personal"
  run_menu_child "$DOTFILES_DIR/install-mac-apps.sh"
  run_menu_child "$DOTFILES_DIR/install-system-apps.sh"
  if [[ -d "$HOME/Applications/calibre.app" || -d "/Applications/calibre.app" ]]; then
    run_menu_child "$DOTFILES_DIR/calibre-sync.sh"
  fi
}

run_install_submenu() {
  local status
  if run_menu_child "$@"; then
    wait_for_menu_return
  else
    status=$?
    if (( status == MENU_CANCELLED )); then
      wait_for_menu_return
    else
      exit "$status"
    fi
  fi
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script is for macOS only."
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  configure_homebrew_for_current_shell
fi
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is missing. Run ./setup.sh first."
  exit 1
fi

while true; do
  print_menu_header "Install apps"
  echo "  1) Install all configured apps"
  echo "  2) Install Office and iWork"
  echo "  3) Citrix Viewer / Caffeinated automation"
  echo "  b) Back"
  echo "  q) Quit"
  echo
  read -r -p "Choose an option: " selection

  case "$selection" in
    1)
      if install_configured_apps; then
        wait_for_menu_return
      else
        status=$?
        (( status == MENU_CANCELLED )) || exit "$status"
      fi
      ;;
    2)
      run_install_submenu "$DOTFILES_DIR/office-installer.sh"
      ;;
    3)
      run_install_submenu "$DOTFILES_DIR/citrix-caffeinated-manager.sh"
      ;;
    b|B|"") exit 0 ;;
    q|Q) exit "$MENU_QUIT" ;;
    *) echo "Invalid choice."; wait_for_menu_return ;;
  esac
done
