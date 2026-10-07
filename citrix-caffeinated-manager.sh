#!/usr/bin/env bash

# Optional Citrix Viewer -> Caffeinated LaunchAgent lifecycle.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/menu-ui.sh"

label="com.nico.citrix-caffeinated"
source_script="$DOTFILES_DIR/macos/.local/bin/citrix-caffeinated-watch"
target_script="$HOME/.local/bin/citrix-caffeinated-watch"
source_plist="$DOTFILES_DIR/optional/citrix-caffeinated/$label.plist"
target_plist="$HOME/Library/LaunchAgents/$label.plist"
old_plist="$DOTFILES_DIR/macos/Library/LaunchAgents/$label.plist"
service="gui/$(id -u)/$label"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This automation is for macOS only."
  exit 1
fi

service_running() {
  launchctl print "$service" >/dev/null 2>&1
}

check_target() {
  local target="$1" expected="$2"

  if [[ -L "$target" ]]; then
    local linked
    linked="$(readlink "$target")"
    if [[ "$linked" == "$expected" || "$linked" == "$old_plist" || "$target" -ef "$expected" ]]; then
      return 0
    fi
  elif [[ ! -e "$target" ]]; then
    return 0
  fi

  echo "Cannot replace an existing file: $target"
  return 1
}

install_agent() {
  if [[ ! -d "/Applications/Caffeinated.app" && ! -d "$HOME/Applications/Caffeinated.app" ]]; then
    echo "Install Caffeinated from the Mac App Store first."
    return 1
  fi

  check_target "$target_script" "$source_script"
  check_target "$target_plist" "$source_plist"

  mkdir -p "$HOME/.local/bin" "$HOME/Library/LaunchAgents"
  if [[ -L "$target_script" && "$(readlink "$target_script")" == "$source_script" ]]; then
    # Replace the one-off absolute link with the relative link managed by Stow.
    rm "$target_script"
  fi
  if [[ ! -e "$target_script" ]]; then
    if ! command -v stow >/dev/null 2>&1; then
      echo "GNU Stow is needed to link the macOS watcher script."
      return 1
    fi
    stow --restow --dir="$DOTFILES_DIR" --target="$HOME" macos
  fi

  if service_running; then
    launchctl bootout "$service"
  fi

  if [[ -L "$target_plist" ]]; then
    rm "$target_plist"
  fi
  ln -s "$source_plist" "$target_plist"
  launchctl bootstrap "gui/$(id -u)" "$target_plist"
  echo "Citrix/Caffeinated automation installed and running."
}

uninstall_agent() {
  check_target "$target_plist" "$source_plist"

  if service_running; then
    launchctl bootout "$service"
  fi
  if [[ -L "$target_plist" ]]; then
    rm "$target_plist"
  fi

  # Leave the watcher script linked by Stow. It does nothing without the agent.
  echo "Citrix/Caffeinated automation stopped and removed."
}

show_status() {
  if [[ -L "$target_plist" && "$(readlink "$target_plist")" == "$source_plist" ]]; then
    echo "Installation: installed"
  elif [[ -L "$target_plist" && "$(readlink "$target_plist")" == "$old_plist" ]]; then
    echo "Installation: old link (reinstall to update)"
  elif [[ -e "$target_plist" || -L "$target_plist" ]]; then
    echo "Installation: another file is present"
  else
    echo "Installation: not installed"
  fi

  if service_running; then
    echo "Service: running"
  else
    echo "Service: stopped"
  fi

  if /usr/bin/pgrep -x 'Citrix Viewer' >/dev/null 2>&1; then
    echo "Citrix Viewer: running"
  else
    echo "Citrix Viewer: stopped"
  fi
}

case "${1:-}" in
  install) install_agent ;;
  uninstall) uninstall_agent ;;
  status) show_status ;;
  "")
    while true; do
      print_menu_header "Citrix Viewer / Caffeinated"
      echo "  1) Install or refresh automation"
      echo "  2) Uninstall automation"
      echo "  3) Show status"
      echo "  b) Back"
      echo "  q) Quit"
      echo
      read -r -p "Choose an option: " selection
      case "$selection" in
        1)
          if confirm_action "Install Citrix/Caffeinated automation?"; then
            install_agent
          fi
          wait_for_menu_return
          ;;
        2)
          if confirm_action "Uninstall Citrix/Caffeinated automation?"; then
            uninstall_agent
          fi
          wait_for_menu_return
          ;;
        3) show_status; wait_for_menu_return ;;
        b|B|"") exit 0 ;;
        q|Q) exit "$MENU_QUIT" ;;
        *) echo "Invalid choice."; wait_for_menu_return ;;
      esac
    done
    ;;
  *)
    echo "Usage: ./citrix-caffeinated-manager.sh [install|uninstall|status]"
    exit 1
    ;;
esac
