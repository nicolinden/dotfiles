#!/usr/bin/env bash

# Single entry point for installing, updating and maintaining this setup.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
    command -v fzf >/dev/null 2>&1
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
      echo
      echo "macOS dotfiles manager"
      echo
      echo "  1) Install optional app profiles"
      echo "  2) Uninstall optional apps"
      echo "  3) Update installed apps and reapply configuration"
      echo "  4) Reapply configuration only"
      echo "  5) Reinstall core tooling"
      echo "  q) Quit"
      echo
      read -r -p "Choose an option: " choice

      case "$choice" in
        1) "$DOTFILES_DIR/install-apps.sh" ;;
        2) "$DOTFILES_DIR/uninstall-apps.sh" ;;
        3) "$DOTFILES_DIR/update.sh" ;;
        4) "$DOTFILES_DIR/reload.sh" ;;
        5) "$DOTFILES_DIR/bootstrap.sh" --core-only ;;
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
      echo
      echo "Ubuntu dotfiles manager"
      if [[ -f /var/run/reboot-required ]]; then
        echo "System restart required after installed updates."
      fi
      echo
      echo "  1) Install or reinstall core tooling"
      echo "  2) Update and upgrade Ubuntu packages, then reapply dotfiles"
      echo "  3) Reapply dotfiles only"
      echo "  4) Restart Ubuntu"
      echo "  q) Quit"
      echo
      read -r -p "Choose an option: " choice

      case "$choice" in
        1) "$DOTFILES_DIR/bootstrap.sh" --core-only ;;
        2) run_linux_update ;;
        3) stow --restow --dir="$DOTFILES_DIR" --target="$HOME" home ;;
        4) restart_linux_system ;;
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
