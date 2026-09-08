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

show_hotkey_status() {
  local skhd_bin="" config_file="$HOME/.config/skhd/skhdrc"

  if [[ -x "/Applications/skhd.app/Contents/MacOS/skhd" ]]; then
    skhd_bin="/Applications/skhd.app/Contents/MacOS/skhd"
  elif command -v skhd >/dev/null 2>&1; then
    skhd_bin="$(command -v skhd)"
  fi

  echo
  echo "Global hotkey service"
  if [[ -n "$skhd_bin" ]]; then
    "$skhd_bin" --status || true
  else
    echo "skhd is not installed."
  fi

  echo
  echo "Configured hotkeys"
  if [[ -r "$config_file" ]]; then
    sed -nE '/^[[:space:]]*($|#)/d; p' "$config_file"
  else
    echo "No readable config found at $config_file."
  fi

  echo
  echo "Command helpers"
  for helper in toggle-aerospace toggle-sketchybar-menu; do
    if [[ -x "$HOME/.local/bin/$helper" ]]; then
      echo "  OK      $HOME/.local/bin/$helper"
    else
      echo "  MISSING $HOME/.local/bin/$helper"
    fi
  done
}

show_hotkey_log() {
  local log_file="$HOME/Library/Logs/skhd.log"

  echo
  echo "This is historical diagnostic output and can contain resolved errors."
  echo "Use option 5 (global hotkey status) for the current service state."
  if [[ -r "$log_file" ]]; then
    echo "Last log change: $(stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S' "$log_file")"
  fi
  show_log "$log_file" "global hotkeys (skhd, historical)"
}

case "$(uname -s)" in
  Darwin)
    print_menu_header "Diagnostics"
    echo "  1) Run health check"
    echo "  2) Show SketchyBar log"
    echo "  3) Show Borders log"
    echo "  4) Show AeroSpace monitor and workspace status"
    echo "  5) Show global hotkey status"
    echo "  6) Show historical global hotkey log"
    echo "  7) Manage Docker containers"
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
      5) show_hotkey_status ;;
      6) show_hotkey_log ;;
      7)
        if command -v docker >/dev/null 2>&1; then
          "$DOTFILES_DIR/docker-manager.sh"
        else
          echo "Docker Desktop is not installed."
        fi
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
