#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/menu-ui.sh"
CONFIG_FILE="$HOME/.config/dotfiles/calibre-sync.conf"
KEY="$HOME/.ssh/noki-server"
DOWNLOADS="$HOME/Downloads"

die() { echo "Error: $*" >&2; exit 1; }
[[ -f "$CONFIG_FILE" ]] || die "Configure the server first."
# shellcheck disable=SC1090
source "$CONFIG_FILE"
REMOTE_DIR=".local/share/downloads-backups"
if [[ -n "${BACKUP_ROOT:-}" ]]; then REMOTE_DIR="$BACKUP_ROOT/downloads-backups"; fi
HOST="$CALIBRE_SYNC_SERVER"
if ! ssh -i "$KEY" -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=5 "$HOST" true >/dev/null 2>&1; then HOST="10.10.2.2"; fi
ssh_cmd() { ssh -i "$KEY" -o IdentitiesOnly=yes -o "IdentityAgent=${NOKI_AGENT_SOCKET:-${SSH_AUTH_SOCK:-}}" "$@"; }
rsync_cmd() { rsync -e "ssh -i $KEY -o IdentitiesOnly=yes -o IdentityAgent=${NOKI_AGENT_SOCKET:-${SSH_AUTH_SOCK:-}}" "$@"; }
load_noki_key_once() { [[ -n "${NOKI_AGENT_SOCKET:-}" ]] && return; eval "$(ssh-agent -s)" >/dev/null; NOKI_AGENT_SOCKET="$SSH_AUTH_SOCK"; ssh-add "$KEY" >/dev/null; }
last_backup() { load_noki_key_once; ssh_cmd "$HOST" "ls -1t '$REMOTE_DIR'/*.tar.gz 2>/dev/null | head -n 1"; }
show_server_space() { ssh_cmd "$HOST" "df -Pm . | awk 'NR==2 {print \$4}'" | xargs -I{} echo "Server space available: {} MB"; }

backup() {
  local tmp archive stamp size_mb
  [[ -d "$DOWNLOADS" ]] || die "No Downloads folder found."
  load_noki_key_once
  size_mb="$(du -sm "$DOWNLOADS" 2>/dev/null | awk '{print $1}')"
  [[ -n "$size_mb" ]] && echo "Downloads size: $size_mb MB"
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/downloads-backup.XXXXXX")"; trap "rm -rf '$tmp'" EXIT
  stamp="$(TZ=Europe/Amsterdam date '+%Y-%m-%d_%H-%M')"; archive="$tmp/downloads-$stamp.tar.gz"
  run_with_progress "Compressing Downloads" tar -czf "$archive" -C "$HOME" Downloads
  ssh_cmd "$HOST" "mkdir -p '$REMOTE_DIR'; find '$REMOTE_DIR' -maxdepth 1 -type f -name '*.tar.gz' -print | sort -r | tail -n +3 | xargs -r rm -f"
  show_server_space
  rsync_cmd --progress "$archive" "$HOST:$REMOTE_DIR/" || die "Downloads upload failed."
  echo "Downloads backup uploaded."
}

restore() {
  local latest confirm tmp
  latest="$(last_backup)"; [[ -n "$latest" ]] || die "No Downloads backup exists on the server."
  load_noki_key_once
  echo "Restore: $(basename "$latest")"; read -r -p "Replace local Downloads? [y/N] " confirm
  [[ "$confirm" =~ ^([yY]|[yY][eE][sS])$ ]] || { echo "Cancelled."; return; }
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/downloads-restore.XXXXXX")"; trap "rm -rf '$tmp'" EXIT
  show_server_space
  rsync_cmd --progress "$HOST:$latest" "$tmp/backup.tar.gz" || die "Downloads download failed."
  rm -rf "$DOWNLOADS"; tar -xzf "$tmp/backup.tar.gz" -C "$HOME"
  echo "Downloads restored."
}

while true; do
  print_menu_header "Downloads backup / restore"
  echo "  1) Back up Downloads folder"
  echo "  2) Restore latest Downloads backup"
  echo "  3) Show latest backup"
  echo "  b) Back"; echo
  read -r -p "Choose an option: " choice
  case "$choice" in
    1) ( backup ) || true; wait_for_menu_return ;;
    2) ( restore ) || true; wait_for_menu_return ;;
    3) last_backup || true; wait_for_menu_return ;;
    b|B|"") exit 0 ;;
    *) echo "Invalid choice." ;;
  esac
done
