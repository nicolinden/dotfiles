#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/menu-ui.sh"

show_log() {
  local file="$1" label="$2"
  echo
  if [[ -r "$file" ]]; then
    echo "Last 100 lines: $label"
    tail -n 100 "$file"
  else
    echo "No readable log file found for $label."
  fi
}

case "$(uname -s)" in
  Darwin)
    print_menu_header "Diagnostics"
    echo "  1) Run health check"
    echo "  2) Show Borders log"
    echo "  3) Show AeroSpace monitor and workspace status"
    echo "  4) Show Raycast toggle script status"
    echo "  5) Manage Docker containers"
    echo "  b) Back"
    echo "  q) Quit"
    echo
    read -r -p "Choose an option: " selection

    case "$selection" in
      1) "$DOTFILES_DIR/health-check.sh" ;;
      2) show_log "$HOME/Library/Logs/Homebrew/borders.log" "Borders" ;;
      3)
        aerospace list-monitors
        echo
        aerospace list-workspaces --all
        ;;
      4)
        if [[ -x "$HOME/.config/raycast/script-commands/toggle-aerospace.sh" ]]; then
          echo "Raycast script is available: $HOME/.config/raycast/script-commands/toggle-aerospace.sh"
          echo "Assign its global hotkey in Raycast Settings → Shortcuts."
        else
          echo "Raycast script is missing. Run ./reload.sh to restore dotfile links."
        fi
        ;;
      5)
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
