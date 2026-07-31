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
    echo "  2) Show SketchyBar log"
    echo "  3) Show Borders log"
    echo "  4) Show AeroSpace monitor and workspace status"
    echo "  b) Back"
    echo
    read -r -p "Choose an option: " selection

    case "$selection" in
      1) "$DOTFILES_DIR/health-check.sh" ;;
      2) show_log "$HOME/Library/Logs/Homebrew/sketchybar.log" "SketchyBar" ;;
      3) show_log "$HOME/Library/Logs/Homebrew/borders.log" "Borders" ;;
      4)
        aerospace list-monitors
        echo
        aerospace list-workspaces --all
        ;;
      b|B|"") exit 0 ;;
      *) echo "Invalid choice." ;;
    esac
    ;;

  Linux)
    print_menu_header "Diagnostics"
    echo "  1) Run health check"
    echo "  2) Show pending package updates"
    echo "  3) Show recent system log entries"
    echo "  b) Back"
    echo
    read -r -p "Choose an option: " selection

    case "$selection" in
      1) "$DOTFILES_DIR/health-check.sh" ;;
      2) apt list --upgradable ;;
      3) journalctl -n 100 --no-pager ;;
      b|B|"") exit 0 ;;
      *) echo "Invalid choice." ;;
    esac
    ;;

  *) exit 1 ;;
esac

wait_for_menu_return
