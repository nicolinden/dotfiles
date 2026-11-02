#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/menu-ui.sh"

case "$(uname -s)" in
  Darwin)
    print_menu_header "Diagnostics"
    echo "  1) Run health check"
    echo "  2) Manage Docker containers"
    echo "  b) Back"
    echo "  q) Quit"
    echo
    read -r -p "Choose an option: " selection

    case "$selection" in
      1) "$DOTFILES_DIR/health-check.sh" ;;
      2)
        if command -v docker >/dev/null 2>&1; then
          "$DOTFILES_DIR/docker-manager.sh"
        else
          echo "Docker Desktop is not installed."
        fi
        ;;
      b|B|"") exit 0 ;;
      q|Q) exit "$MENU_QUIT" ;;
      *) echo "Invalid choice." ;;
    esac
    ;;

  Linux)
    print_menu_header "Diagnostics"
    echo "  1) Run health check"
    echo "  2) Show pending package updates"
    echo "  3) Show recent system log entries"
    echo "  b) Back"
    echo "  q) Quit"
    echo
    read -r -p "Choose an option: " selection

    case "$selection" in
      1) "$DOTFILES_DIR/health-check.sh" ;;
      2) apt list --upgradable ;;
      3) journalctl -n 100 --no-pager ;;
      b|B|"") exit 0 ;;
      q|Q) exit "$MENU_QUIT" ;;
      *) echo "Invalid choice." ;;
    esac
    ;;

  *) exit 1 ;;
esac

wait_for_menu_return
