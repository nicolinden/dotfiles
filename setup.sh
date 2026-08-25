#!/usr/bin/env bash

# Single entry point for installing, updating and maintaining this setup.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/menu-ui.sh"

run_submenu() {
  local status

  if "$@"; then
    return 0
  else
    status=$?
  fi
  if (( status == MENU_CANCELLED )); then
    return 0
  fi

  return "$status"
}

configure_homebrew_for_current_shell() {
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

macos_core_ready() {
  command -v brew >/dev/null 2>&1 &&
    brew list stow >/dev/null 2>&1 &&
    brew list sketchybar >/dev/null 2>&1
}

linux_core_ready() {
  command -v git >/dev/null 2>&1 &&
    command -v stow >/dev/null 2>&1 &&
    command -v fzf >/dev/null 2>&1 &&
    command -v starship >/dev/null 2>&1 &&
    command -v lazygit >/dev/null 2>&1 &&
    command -v lazydocker >/dev/null 2>&1
}

run_linux_update() {
  echo "Updating and upgrading Ubuntu packages..."
  sudo apt-get update
  sudo apt-get upgrade -y
  stow --restow --dir="$DOTFILES_DIR" --target="$HOME" home
  echo "Ubuntu packages and dotfiles are up to date."
}

restart_linux_system() {
  echo
  echo "This will immediately restart Ubuntu and close all open applications."
  read -r -p "Restart now? [y/N] " confirm

  case "$confirm" in
    y|Y|yes|YES)
      sudo systemctl reboot
      ;;
    *)
      echo "Restart cancelled."
      ;;
  esac
}

case "$(uname -s)" in
  Darwin)
    configure_homebrew_for_current_shell
    if ! macos_core_ready; then
      echo "Core macOS tooling is missing. Installing it now..."
      "$DOTFILES_DIR/bootstrap.sh" --core-only
      configure_homebrew_for_current_shell
    fi

    while true; do
      print_menu_header "macOS manager"
      echo "  1) (Re)install and apply configuration"
      echo "  2) Manage apps"
      echo "  3) Update installed apps"
      echo "  4) Diagnostics"
      echo "  5) Backup / restore"
      echo "  6) Reload configuration after git pull"
      echo "  q) Quit"
      echo
      read -r -p "Choose an option: " choice

      case "$choice" in
        1)
          echo
          echo "This will ensure core tooling is installed, reapply your Stow files,"
          echo "start AeroSpace and restart SketchyBar and Borders. Optional apps are unchanged."
          if confirm_action "(Re)install and apply configuration?"; then
            "$DOTFILES_DIR/bootstrap.sh" --core-only
            wait_for_menu_return
          else
            echo "Cancelled."
          fi
          ;;
        2) run_submenu "$DOTFILES_DIR/install-apps.sh" ;;
        3) run_submenu "$DOTFILES_DIR/update-menu.sh" ;;
        4) run_submenu "$DOTFILES_DIR/diagnostics.sh" ;;
        5) run_submenu "$DOTFILES_DIR/backup-restore-manager.sh" ;;
        6)
          echo
          echo "This reapplies Stow configuration and reloads AeroSpace, SketchyBar,"
          echo "Borders and an active tmux server. It does not install or update apps."
          if confirm_action "Reload configuration after git pull?"; then
            "$DOTFILES_DIR/reload.sh"
            wait_for_menu_return
          else
            echo "Cancelled."
          fi
          ;;
        q|Q|"") exit 0 ;;
        *) echo "Invalid choice." ;;
      esac
    done
    ;;

  Linux)
    if ! linux_core_ready; then
      echo "Core Ubuntu tooling is missing. Installing it now..."
      "$DOTFILES_DIR/bootstrap.sh" --core-only
    fi

    while true; do
      print_menu_header "Ubuntu manager"
      if [[ -f /var/run/reboot-required ]]; then
        echo "System restart required after installed updates."
      fi
      echo
      echo "  1) (Re)install and apply configuration"
      echo "  2) Manage optional tools"
      echo "  3) Update Ubuntu packages"
      echo "  4) Diagnostics"
      echo "  5) Restart Ubuntu"
      echo "  6) Manage Docker containers"
      echo "  7) SAP HANA Trial"
      echo "  8) Reload configuration after git pull"
      echo "  q) Quit"
      echo
      read -r -p "Choose an option: " choice

      case "$choice" in
        1)
          echo
          echo "This will ensure core Ubuntu tools are installed, reapply your Stow files,"
          echo "and install or refresh Starship, LazyGit and LazyDocker."
          if confirm_action "(Re)install and apply configuration?"; then
            "$DOTFILES_DIR/bootstrap.sh" --core-only
            wait_for_menu_return
          else
            echo "Cancelled."
          fi
          ;;
        2) run_submenu "$DOTFILES_DIR/install-linux-apps.sh" ;;
        3)
          echo
          echo "This will refresh Ubuntu package lists, upgrade installed packages"
          echo "and reapply your shared Stow configuration."
          if confirm_action "Update Ubuntu packages?"; then
            run_linux_update
            wait_for_menu_return
          else
            echo "Cancelled."
          fi
          ;;
        4) run_submenu "$DOTFILES_DIR/diagnostics.sh" ;;
        5) restart_linux_system ;;
        6)
          if command -v docker >/dev/null 2>&1; then
            run_submenu "$DOTFILES_DIR/docker-manager.sh"
          else
            echo "Docker is not installed."
            wait_for_menu_return
          fi
          ;;
        7)
          run_submenu "$DOTFILES_DIR/sap-hana-manager.sh"
          ;;
        8)
          echo
          echo "This reapplies the shared Stow configuration and reloads an active"
          echo "tmux server. It does not install or update apps."
          if confirm_action "Reload configuration after git pull?"; then
            "$DOTFILES_DIR/reload.sh"
            wait_for_menu_return
          else
            echo "Cancelled."
          fi
          ;;
        q|Q|"") exit 0 ;;
        *) echo "Invalid choice." ;;
      esac
    done
    ;;

  *)
    echo "Unsupported operating system."
    exit 1
    ;;
esac
