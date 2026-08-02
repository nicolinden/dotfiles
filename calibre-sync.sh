#!/usr/bin/env bash

# Safely use one Calibre library from multiple Macs. Each Mac works locally;
# this script uses the server only as the synchronized hand-off point.
set -euo pipefail

STATE_DIR="$HOME/.config/dotfiles"
CONFIG_FILE="$STATE_DIR/calibre-sync.conf"
LIBRARY_DIR="${CALIBRE_LIBRARY_DIR:-$HOME/Calibre Library}"
DEFAULT_SERVER="server.nokionline.com"
FALLBACK_SERVER="10.10.2.2"
DEFAULT_REMOTE_DIR=".local/share/calibre-library"
CALIBRE_SSH_KEY="$HOME/.ssh/id_ed25519_calibre"

die() {
  echo "Error: $*" >&2
  exit 1
}

calibre_ssh() {
  if [[ -f "$CALIBRE_SSH_KEY" ]]; then
    ssh -i "$CALIBRE_SSH_KEY" -o IdentitiesOnly=yes "$@"
  else
    ssh "$@"
  fi
}

calibre_rsync() {
  if [[ -f "$CALIBRE_SSH_KEY" ]]; then
    rsync -e "ssh -i $CALIBRE_SSH_KEY -o IdentitiesOnly=yes" "$@"
  else
    rsync "$@"
  fi
}

load_config() {
  [[ -f "$CONFIG_FILE" ]] || return 1
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
  [[ -n "${CALIBRE_SYNC_SERVER:-}" && -n "${CALIBRE_SYNC_REMOTE_DIR:-}" ]] || return 1
}

save_config() {
  mkdir -p "$STATE_DIR"
  cat >"$CONFIG_FILE" <<EOF
# This file is local to this Mac and is intentionally not stored in Git.
CALIBRE_SYNC_SERVER=$CALIBRE_SYNC_SERVER
CALIBRE_SYNC_REMOTE_DIR=$CALIBRE_SYNC_REMOTE_DIR
EOF
  chmod 600 "$CONFIG_FILE"
}

validate_remote_dir() {
  [[ "$1" =~ ^[A-Za-z0-9._/-]+$ ]] && [[ "$1" != /* ]] && [[ "$1" != *".."* ]]
}

configure() {
  local server remote_dir
  echo "Configure the central Calibre library."
  read -r -p "Server [$DEFAULT_SERVER]: " server
  server="${server:-$DEFAULT_SERVER}"
  read -r -p "Server folder, relative to the remote home [$DEFAULT_REMOTE_DIR]: " remote_dir
  remote_dir="${remote_dir:-$DEFAULT_REMOTE_DIR}"
  validate_remote_dir "$remote_dir" || die "Use a relative folder name containing only letters, numbers, ., _, / or -."

  CALIBRE_SYNC_SERVER="$server"
  CALIBRE_SYNC_REMOTE_DIR="$remote_dir"
  save_config
  echo "Saved. The library will be stored at ~/$CALIBRE_SYNC_REMOTE_DIR on $CALIBRE_SYNC_SERVER."
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

upload_library() {
  local confirm
  load_config || die "Configure Calibre sync first."
  require_calibre_closed
  require_connection
  [[ -f "$LIBRARY_DIR/metadata.db" ]] || die "No local Calibre library found at: $LIBRARY_DIR"
  echo
  read -r -p "Upload this Mac's library to the server? [y/N] " confirm
  [[ "$confirm" =~ ^([yY]|[yY][eE][sS])$ ]] || { echo "Cancelled."; return; }
  backup_server_library
  calibre_rsync -a --delete "$LIBRARY_DIR/" "$(remote_target)"
  echo "Upload complete. The server keeps the newest three pre-upload backups."
}

download_library() {
  local confirm
  load_config || die "Configure Calibre sync first."
  require_calibre_closed
  require_connection
  server_has_library || die "No library exists on the server yet. Upload one from the Mac that has your books."
  echo
  echo "This replaces the local Calibre library with the server version."
  read -r -p "Download and replace the local library? [y/N] " confirm
  [[ "$confirm" =~ ^([yY]|[yY][eE][sS])$ ]] || { echo "Cancelled."; return; }
  calibre_rsync -a --delete "$(remote_target)" "$LIBRARY_DIR/"
  echo "Download complete. You can now open Calibre and use your Kobo."
}

show_status() {
  if ! load_config; then
    echo "Calibre sync has not been configured on this Mac."
    return
  fi
  echo "Local library: $LIBRARY_DIR"
  echo "Server: $CALIBRE_SYNC_SERVER:~/$CALIBRE_SYNC_REMOTE_DIR"
  echo "Upload before switching Macs; download before working on the other Mac."
}

while true; do
  echo
  echo "Calibre library sync"
  echo "  1) Configure server"
  echo "  2) Upload this Mac's library"
  echo "  3) Download server library to this Mac"
  echo "  4) Status"
  echo "  b) Back"
  echo
  read -r -p "Choose an option: " choice
  case "$choice" in
    # Run actions in a subshell: a failed connection or a missing setup must
    # return to this menu, never close the complete dotfiles manager.
    1) ( configure ) || true ;;
    2) ( upload_library ) || true ;;
    3) ( download_library ) || true ;;
    4) ( show_status ) || true ;;
    b|B|"") exit 0 ;;
    *) echo "Invalid choice." ;;
  esac
done
