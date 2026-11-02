#!/usr/bin/env bash

# One menu for installing, updating, and removing macOS apps.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/menu-ui.sh"

run_app_action() {
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

while true; do
  print_menu_header "Manage apps"
  echo "  1) Install apps"
  echo "  2) Update apps"
  echo "  3) Remove apps"
  echo "  b) Back"
  echo "  q) Quit"
  echo
  read -r -p "Choose an option: " selection

  case "$selection" in
    1) run_app_action "$DOTFILES_DIR/install-apps.sh" ;;
    2) run_app_action "$DOTFILES_DIR/update.sh" ;;
    3) run_app_action "$DOTFILES_DIR/uninstall-apps.sh" ;;
    b|B|"") exit 0 ;;
    q|Q) exit "$MENU_QUIT" ;;
    *) echo "Invalid choice."; wait_for_menu_return ;;
  esac
done
