#!/usr/bin/env bash

# One entry point for all personal backups and restores.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/menu-ui.sh"
CONFIG_FILE="$HOME/.config/dotfiles/calibre-sync.conf"

configured() {
  [[ -f "$CONFIG_FILE" ]]
}

while true; do
  print_menu_header "Backup / restore"
  echo
  echo "  1) Server setup"
  if configured; then
    echo "  2) SSH key backup / restore"
    echo "  3) Calibre backup / restore"
    echo "  4) Downloads backup / restore"
  fi
  echo "  b) Back"
  echo
  read -r -p "Choose an option: " choice
  case "$choice" in
    1) CALIBRE_CONFIGURE_ONLY=1 "$DOTFILES_DIR/calibre-sync.sh" ;;
    2) configured && "$DOTFILES_DIR/ssh-key-manager.sh" || true ;;
    3) configured && "$DOTFILES_DIR/calibre-sync.sh" || true ;;
    4) configured && "$DOTFILES_DIR/downloads-backup-manager.sh" || true ;;
    b|B|"") exit 0 ;;
    *) echo "Invalid choice." ;;
  esac
done
