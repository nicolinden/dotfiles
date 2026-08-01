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
  run_with_progress "$label installeren" \
    env HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications" \
    caffeinate -i brew bundle install --file="$DOTFILES_DIR/$file"
}

install_all_optional_apps() {
  print_menu_header "Confirm all optional macOS apps"
  echo "This will install or update every optional app profile:"
  echo
  echo "Development:"
  show_brewfile_plan "$DOTFILES_DIR/Brewfile.dev"
  echo "Personal:"
  show_brewfile_plan "$DOTFILES_DIR/Brewfile.personal"
  echo "Personal Mac App Store apps:"
  show_mas_plan "$DOTFILES_DIR/Brewfile.mas"
  echo "Office and iWork:"
  show_mas_plan "$DOTFILES_DIR/Brewfile.office.mas"
  echo "System apps:"
  for label in "${SYSTEM_LABELS[@]}"; do
    printf '  - %s\n' "$label"
  done

  if ! confirm_action "Install all optional apps?"; then
    echo "Cancelled."
    return "$MENU_CANCELLED"
  fi

  export DOTFILES_ASSUME_YES=1
  export DOTFILES_INSTALL_ALL=1

  install_brewfile "Brewfile.dev" "development apps"
  install_brewfile "Brewfile.personal" "personal apps"
  "$DOTFILES_DIR/install-mac-apps.sh"
  "$DOTFILES_DIR/office-installer.sh"
  "$DOTFILES_DIR/install-system-apps.sh"
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

while true; do
  print_menu_header "Optional macOS app profiles"
  echo "  1) Development apps"
  echo "  2) Personal apps"
  echo "  3) Personal Mac App Store apps"
  echo "  4) Office and iWork"
  echo "  5) System apps"
  echo "  6) Remove optional apps"
  echo "  a) Install all optional apps"
  echo "  b) Back"
  echo
  read -r -p "Choose an option: " selection

  case "$selection" in
    1)
      if install_brewfile "Brewfile.dev" "development apps"; then
        wait_for_menu_return
        exit 0
      elif [[ $? -eq "$MENU_CANCELLED" ]]; then
        continue
      else
        exit "$?"
      fi
      ;;
    2)
      if install_brewfile "Brewfile.personal" "personal apps"; then
        wait_for_menu_return
        exit 0
      elif [[ $? -eq "$MENU_CANCELLED" ]]; then
        continue
      else
        exit "$?"
      fi
      ;;
    3)
      if "$DOTFILES_DIR/install-mac-apps.sh"; then
        wait_for_menu_return
        exit 0
      elif [[ $? -eq "$MENU_CANCELLED" ]]; then
        continue
      else
        exit "$?"
      fi
      ;;
    4)
      if "$DOTFILES_DIR/office-installer.sh"; then
        wait_for_menu_return
        exit 0
      elif [[ $? -eq "$MENU_CANCELLED" ]]; then
        continue
      else
        exit "$?"
      fi
      ;;
    5)
      if "$DOTFILES_DIR/install-system-apps.sh"; then
        wait_for_menu_return
        exit 0
      elif [[ $? -eq "$MENU_CANCELLED" ]]; then
        continue
      else
        exit "$?"
      fi
      ;;
    6)
      "$DOTFILES_DIR/uninstall-apps.sh"
      wait_for_menu_return
      exit 0
      ;;
    a|A)
      if install_all_optional_apps; then
        wait_for_menu_return
        exit 0
      elif [[ $? -eq "$MENU_CANCELLED" ]]; then
        continue
      else
        exit "$?"
      fi
      ;;
    b|B|"") exit 0 ;;
    *) echo "Invalid choice."; wait_for_menu_return ;;
  esac
done
