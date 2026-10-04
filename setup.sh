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
  if (( status == MENU_QUIT )); then
    exit 0
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
    brew list --cask aerospace >/dev/null 2>&1
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
  local remaining_updates remaining_count held_packages
  local upgrade_options=(
    --no-remove
    --with-new-pkgs
    -o APT::Get::Always-Include-Phased-Updates=false
    -o APT::Get::Never-Include-Phased-Updates=false
  )

  echo "Refreshing package lists (stop if any repository cannot be refreshed)..."
  sudo apt-get -o APT::Update::Error-Mode=any update
  echo "Upgrading packages with required new dependencies, respecting holds and phased rollout..."
  sudo apt-get "${upgrade_options[@]}" upgrade -y
  stow --restow --dir="$DOTFILES_DIR" --target="$HOME" home
  echo "Conservative package update completed; shared dotfiles reapplied."
  echo
  remaining_updates="$(LC_ALL=C apt list --upgradable 2>/dev/null)"
  remaining_updates="$(printf '%s\n' "$remaining_updates" | sed '/^Listing\.\.\.$/d; /^[[:space:]]*$/d')"
  if [[ -n "$remaining_updates" ]]; then
    remaining_count="$(printf '%s\n' "$remaining_updates" | awk 'END { print NR }')"
    echo "$remaining_count package update(s) remain; not all available updates were installed."
    printf '%s\n' "$remaining_updates"
    echo "APT may defer updates due to phasing, holds or dependency conflicts."
    echo "See APT's output above for the reason; these updates are not forced."
  else
    echo "0 package updates remain in the current APT package lists."
  fi
  held_packages="$(apt-mark showhold)"
  if [[ -n "$held_packages" ]]; then
    echo "Explicitly held packages:"
    printf '%s\n' "$held_packages"
  fi
  echo "ESM Apps updates require an enabled Ubuntu Pro entitlement."
  if [[ -f /var/run/reboot-required ]]; then
    echo "A restart is required to finish applying installed updates; no automatic reboot."
  fi
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

linux_dotfiles_menu() {
  local choice
  while true; do
    print_menu_header "Dotfiles setup"
    echo "  1) (Re)install and apply configuration"
    echo "  2) Manage optional tools"
    echo "  3) Reload configuration after git pull"
    echo "  b) Back"
    echo "  q) Quit"
    echo
    read -r -p "Choose an option: " choice
    case "$choice" in
      1)
        echo "This reapplies Stow files and installs or refreshes core Ubuntu tools."
        if confirm_action "(Re)install and apply configuration?"; then
          "$DOTFILES_DIR/bootstrap.sh" --core-only
          wait_for_menu_return
        fi
        ;;
      2) run_submenu "$DOTFILES_DIR/install-linux-apps.sh" ;;
      3)
        echo "This reapplies Stow files and reloads an active tmux server."
        if confirm_action "Reload configuration after git pull?"; then
          "$DOTFILES_DIR/reload.sh"
          wait_for_menu_return
        fi
        ;;
      b|B|"") return ;;
      q|Q) exit 0 ;;
      *) echo "Invalid choice."; wait_for_menu_return ;;
    esac
  done
}

linux_server_menu() {
  local choice
  while true; do
    print_menu_header "Manage Ubuntu server"
    [[ -f /var/run/reboot-required ]] && echo "System restart required after installed updates."
    echo "  1) Show available package updates"
    echo "  2) Update Ubuntu packages (conservative)"
    echo "  3) Health check and Matter IPv6"
    echo "  4) Restart Ubuntu"
    echo "  b) Back"
    echo "  q) Quit"
    echo
    read -r -p "Choose an option: " choice
    case "$choice" in
      1)
        echo "Refreshing package lists..."
        sudo apt-get -o APT::Update::Error-Mode=any update && apt list --upgradable
        wait_for_menu_return
        ;;
      2)
        echo "This respects holds and phased rollout; it does not remove packages or reboot."
        if confirm_action "Update Ubuntu packages?"; then
          run_linux_update
          wait_for_menu_return
        fi
        ;;
      3) run_submenu "$DOTFILES_DIR/server-health-menu.sh" ;;
      4) restart_linux_system ;;
      b|B|"") return ;;
      q|Q) exit 0 ;;
      *) echo "Invalid choice."; wait_for_menu_return ;;
    esac
  done
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
      echo "  7) SAP HANA Trial on server"
      echo "  q) Quit"
      echo
      read -r -p "Choose an option: " choice

      case "$choice" in
        1)
          echo
          echo "This will ensure core tooling is installed, reapply your Stow files,"
          echo "start AeroSpace and restart Borders. Optional apps are unchanged."
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
          echo "This reapplies Stow configuration and reloads AeroSpace, Borders"
          echo "and an active tmux server. It does not install or update apps."
          if confirm_action "Reload configuration after git pull?"; then
            "$DOTFILES_DIR/reload.sh"
            wait_for_menu_return
          else
            echo "Cancelled."
          fi
          ;;
        7) run_submenu "$DOTFILES_DIR/sap-hana-remote.sh" ;;
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
      echo "  1) Dotfiles setup"
      echo "  2) Manage Ubuntu server"
      echo "  3) Manage Docker containers and images"
      echo "  4) SAP HANA Trial"
      echo "  q) Quit"
      echo
      read -r -p "Choose an option: " choice

      case "$choice" in
        1) linux_dotfiles_menu ;;
        2) linux_server_menu ;;
        3)
          if command -v docker >/dev/null 2>&1; then
            run_submenu "$DOTFILES_DIR/docker-manager.sh"
          else
            echo "Docker is not installed."
            wait_for_menu_return
          fi
          ;;
        4)
          run_submenu "$DOTFILES_DIR/sap-hana-manager.sh"
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
