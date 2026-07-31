#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/menu-ui.sh"

print_menu_header "Update installed apps"
echo "  1) Update everything (Homebrew and Mac App Store)"
echo "  2) Update managed Homebrew apps only"
echo "  b) Back"
echo
read -r -p "Choose an option: " selection

case "$selection" in
  1)
    echo
    echo "This will update every Homebrew app and command-line package,"
    echo "update Mac App Store apps, remove old downloads and reapply configuration."
    if confirm_action "Update everything?"; then
      "$DOTFILES_DIR/update.sh"
    else
      echo "Cancelled."
      exit "$MENU_CANCELLED"
    fi
    ;;
  2)
    echo
    echo "This will update only already-installed Homebrew packages declared"
    echo "in Brewfile, Brewfile.dev and Brewfile.personal, then reapply configuration."
    echo
    echo "Managed package definitions:"
    show_brewfile_plan "$DOTFILES_DIR/Brewfile"
    show_brewfile_plan "$DOTFILES_DIR/Brewfile.dev"
    show_brewfile_plan "$DOTFILES_DIR/Brewfile.personal"
    if confirm_action "Update managed Homebrew packages?"; then
      "$DOTFILES_DIR/update-managed-brew.sh"
    else
      echo "Cancelled."
      exit "$MENU_CANCELLED"
    fi
    ;;
  b|B|"") exit 0 ;;
  *) echo "Invalid choice." ;;
esac

wait_for_menu_return
