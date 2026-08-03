#!/usr/bin/env bash

# Safely use one Calibre library from multiple Macs. Each Mac works locally;
# this script uses the server only as the synchronized hand-off point.
set -euo pipefail

STATE_DIR="$HOME/.config/dotfiles"
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/menu-ui.sh"
CONFIG_FILE="$STATE_DIR/calibre-sync.conf"
LIBRARY_DIR="${CALIBRE_LIBRARY_DIR:-$HOME/Calibre Library}"
DEFAULT_SERVER="server.nokionline.com"
FALLBACK_SERVER="10.10.2.2"
DEFAULT_BACKUP_ROOT=".local/share"
CALIBRE_SSH_KEY="$HOME/.ssh/noki-server"

die() {
  echo "Error: $*" >&2
  exit 1
}

calibre_ssh() {
  if [[ -f "$CALIBRE_SSH_KEY" ]]; then
    if [[ -n "${NOKI_AGENT_SOCKET:-}" ]]; then
      ssh -i "$CALIBRE_SSH_KEY" -o IdentitiesOnly=yes -o "IdentityAgent=$NOKI_AGENT_SOCKET" "$@"
    else
      ssh -i "$CALIBRE_SSH_KEY" -o IdentitiesOnly=yes "$@"
    fi
  else
    ssh "$@"
  fi
}

calibre_rsync() {
  local ssh_command
  if [[ -f "$CALIBRE_SSH_KEY" ]]; then
    ssh_command="ssh -i $CALIBRE_SSH_KEY -o IdentitiesOnly=yes"
    [[ -n "${NOKI_AGENT_SOCKET:-}" ]] && ssh_command+=" -o IdentityAgent=$NOKI_AGENT_SOCKET"
    rsync -e "$ssh_command" "$@"
  else
    rsync "$@"
  fi
}

load_noki_key_once() {
  [[ -n "${NOKI_AGENT_SOCKET:-}" ]] && return
  eval "$(ssh-agent -s)" >/dev/null
  NOKI_AGENT_SOCKET="$SSH_AUTH_SOCK"
  ssh-add "$CALIBRE_SSH_KEY" >/dev/null
}

load_config() {
  [[ -f "$CONFIG_FILE" ]] || return 1
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
  if [[ -z "${BACKUP_ROOT:-}" && "${CALIBRE_SYNC_REMOTE_DIR:-}" == */calibre-library ]]; then
    BACKUP_ROOT="${CALIBRE_SYNC_REMOTE_DIR%/calibre-library}"
  fi
  [[ -n "${CALIBRE_SYNC_SERVER:-}" && -n "${BACKUP_ROOT:-}" ]] || return 1
  CALIBRE_SYNC_REMOTE_DIR="$BACKUP_ROOT/calibre-library"
}

save_config() {
  mkdir -p "$STATE_DIR"
  cat >"$CONFIG_FILE" <<EOF
# This file is local to this Mac and is intentionally not stored in Git.
CALIBRE_SYNC_SERVER=$CALIBRE_SYNC_SERVER
BACKUP_ROOT=$BACKUP_ROOT
EOF
  chmod 600 "$CONFIG_FILE"
}

validate_remote_dir() {
  [[ "$1" =~ ^[A-Za-z0-9._/-]+$ ]] && [[ "$1" != /* ]] && [[ "$1" != *".."* ]]
}

configure() {
  local server backup_root
  echo "Configure the central backup storage."
  read -r -p "Server [$DEFAULT_SERVER]: " server
  server="${server:-$DEFAULT_SERVER}"
  read -r -p "Backup root folder, relative to the remote home [$DEFAULT_BACKUP_ROOT]: " backup_root
  backup_root="${backup_root:-$DEFAULT_BACKUP_ROOT}"
  validate_remote_dir "$backup_root" || die "Use a relative folder name containing only letters, numbers, ., _, / or -."

  CALIBRE_SYNC_SERVER="$server"
  BACKUP_ROOT="$backup_root"
  CALIBRE_SYNC_REMOTE_DIR="$BACKUP_ROOT/calibre-library"
  save_config
  echo "Saved. Backup storage is configured on $CALIBRE_SYNC_SERVER."
}

require_connection() {
  command -v ssh >/dev/null 2>&1 || die "SSH is not available."
  command -v rsync >/dev/null 2>&1 || die "rsync is not available."
  CALIBRE_SYNC_ACTIVE_SERVER="$CALIBRE_SYNC_SERVER"
  if calibre_ssh -o ConnectTimeout=10 "$CALIBRE_SYNC_ACTIVE_SERVER" true; then
    return
  fi

  if [[ "$CALIBRE_SYNC_SERVER" == "$DEFAULT_SERVER" ]] && \
     calibre_ssh -o ConnectTimeout=5 "$FALLBACK_SERVER" true; then
    CALIBRE_SYNC_ACTIVE_SERVER="$FALLBACK_SERVER"
    echo "Primary server name unavailable; using the local fallback at $FALLBACK_SERVER."
    return
  fi

  die "Cannot reach the server. Connect Tailscale or the local network, then check your SSH key."
}

remote_path() {
  printf '%s' "$CALIBRE_SYNC_REMOTE_DIR"
}

remote_target() {
  printf '%s:%s/' "${CALIBRE_SYNC_ACTIVE_SERVER:-$CALIBRE_SYNC_SERVER}" "$CALIBRE_SYNC_REMOTE_DIR"
}

show_server_space() {
  local available
  available="$(calibre_ssh "$CALIBRE_SYNC_ACTIVE_SERVER" "df -Pm . | awk 'NR==2 {print \$4}'" 2>/dev/null || true)"
  [[ -n "$available" ]] && echo "Server space available: $available MB"
}

calibre_is_running() {
  pgrep -x calibre >/dev/null 2>&1
}

require_calibre_closed() {
  calibre_is_running && die "Close Calibre before synchronizing the library."
}

server_has_library() {
  calibre_ssh "${CALIBRE_SYNC_ACTIVE_SERVER:-$CALIBRE_SYNC_SERVER}" "test -f '$(remote_path)/metadata.db'"
}

backup_server_library() {
  local timestamp backup_dir
  server_has_library || return
  timestamp="$(date -u '+%Y%m%dT%H%M%SZ')"
  backup_dir="${CALIBRE_SYNC_REMOTE_DIR}-backups"
  calibre_ssh "$CALIBRE_SYNC_ACTIVE_SERVER" "mkdir -p '$backup_dir' && tar -czf '$backup_dir/calibre-library-$timestamp.tar.gz' -C '$(remote_path)' . && ls -1t '$backup_dir'/*.tar.gz 2>/dev/null | tail -n +4 | xargs -r rm -f" \
    || die "Could not create the server backup; local library was not uploaded."
}

backup_downloads() {
  local timestamp backup_dir temp_dir archive
  load_config || die "Configure Calibre backup first."
  [[ -d "$HOME/Downloads" ]] || die "No Downloads folder found."
  require_connection
  timestamp="$(date -u '+%Y%m%dT%H%M%SZ')"
  backup_dir="${CALIBRE_SYNC_REMOTE_DIR}-downloads-backups"
  temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/calibre-downloads-backup.XXXXXX")"
  archive="$temp_dir/downloads-$timestamp.tar.gz"
  trap "rm -rf '$temp_dir'" EXIT
  echo "Creating compressed Downloads backup..."
  tar -czf "$archive" -C "$HOME" Downloads
  calibre_ssh "$CALIBRE_SYNC_ACTIVE_SERVER" "mkdir -p '$backup_dir' && ls -1t '$backup_dir'/*.tar.gz 2>/dev/null | tail -n +3 | xargs -r rm -f"
  calibre_rsync "$archive" "$CALIBRE_SYNC_ACTIVE_SERVER:$backup_dir/"
  echo "Downloads backup uploaded. The server keeps the newest three backups."
}

upload_library() {
  local confirm
  load_config || die "Configure Calibre sync first."
  load_noki_key_once
  require_calibre_closed
  require_connection
  [[ -f "$LIBRARY_DIR/metadata.db" ]] || die "No local Calibre library found at: $LIBRARY_DIR"
  echo
  read -r -p "Upload this Mac's library to the server? [y/N] " confirm
  [[ "$confirm" =~ ^([yY]|[yY][eE][sS])$ ]] || { echo "Cancelled."; return; }
  backup_server_library
  show_server_space
  calibre_rsync -a --delete --progress "$LIBRARY_DIR/" "$(remote_target)" || die "Library upload failed."
  echo "Upload complete. The server keeps the newest three pre-upload backups."
}

download_library() {
  local confirm
  load_config || die "Configure Calibre sync first."
  load_noki_key_once
  require_calibre_closed
  require_connection
  server_has_library || die "No library exists on the server yet. Upload one from the Mac that has your books."
  echo
  echo "This replaces the local Calibre library with the server version."
  read -r -p "Download and replace the local library? [y/N] " confirm
  [[ "$confirm" =~ ^([yY]|[yY][eE][sS])$ ]] || { echo "Cancelled."; return; }
  show_server_space
  calibre_rsync -a --delete --progress "$(remote_target)" "$LIBRARY_DIR/" || die "Library download failed."
  echo "Download complete. You can now open Calibre and use your Kobo."
}

show_status() {
  local local_status online_status
  if ! load_config; then
    echo "Calibre backup has not been configured on this Mac."
    return
  fi
  [[ -f "$LIBRARY_DIR/metadata.db" ]] || die "No local Calibre library found at: $LIBRARY_DIR"
  load_noki_key_once
  require_connection
  local_status="$(TZ=Europe/Amsterdam stat -f 'modified %Sm, %z bytes' -t '%d-%m-%Y %H:%M %Z' "$LIBRARY_DIR/metadata.db")"
  online_status="$(calibre_ssh "$CALIBRE_SYNC_ACTIVE_SERVER" "TZ=Europe/Amsterdam date -d \"\$(stat -c %y '$(remote_path)/metadata.db')\" '+modified %d-%m-%Y %H:%M %Z'; stat -c '%s bytes' '$(remote_path)/metadata.db'" 2>/dev/null | tr '\n' ', ')" \
    || online_status="not found"
  echo "Local library: $LIBRARY_DIR"
  echo "  $local_status"
  echo "Server library: $CALIBRE_SYNC_ACTIVE_SERVER:~/$CALIBRE_SYNC_REMOTE_DIR"
  echo "  $online_status"
  echo "Upload before switching Macs; download before working on the other Mac."
}

if [[ "${CALIBRE_CONFIGURE_ONLY:-}" == "1" ]]; then
  configure
  exit 0
fi

while true; do
  print_menu_header "Calibre backup / restore"
  echo
  if load_config; then
    echo "  1) Upload this Mac's library"
    echo "  2) Download server library to this Mac"
    echo "  3) Show local and server status"
  else
    echo "Configure the server first to show backup and restore actions."
  fi
  echo "  b) Back"
  echo
  read -r -p "Choose an option: " choice
  case "$choice" in
    # Run actions in a subshell: a failed connection or a missing setup must
    # return to this menu, never close the complete dotfiles manager.
    1) load_config && ( upload_library ) || true; wait_for_menu_return ;;
    2) load_config && ( download_library ) || true; wait_for_menu_return ;;
    3) load_config && ( show_status ) || true; wait_for_menu_return ;;
    b|B|"") exit 0 ;;
    *) echo "Invalid choice." ;;
  esac
done
