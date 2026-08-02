#!/usr/bin/env bash

# Create a consistent, timestamped snapshot of the master library in iCloud.
set -euo pipefail

STATE_DIR="$HOME/.config/dotfiles"
ROLE_FILE="$STATE_DIR/calibre-role"
LIBRARY_DIR="${CALIBRE_LIBRARY_DIR:-$HOME/Calibre Library}"
ICLOUD_ROOT="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
BACKUP_DIR="${CALIBRE_BACKUP_DIR:-$ICLOUD_ROOT/Calibre Backups}"
SERVER_PLIST="$HOME/Library/LaunchAgents/com.nicodotfiles.calibre-server.plist"
timestamp="$(date -u '+%Y%m%dT%H%M%SZ')"
archive="$BACKUP_DIR/calibre-library-$timestamp.tar.gz"
temporary_archive="$(mktemp "${TMPDIR:-/tmp}/calibre-library.XXXXXX.tar.gz")"
server_was_loaded=false

if [[ ! -f "$ROLE_FILE" ]] || [[ "$(<"$ROLE_FILE")" != "master" ]]; then
  echo "Backups run only on the configured Calibre master."
  exit 0
fi

if [[ ! -f "$LIBRARY_DIR/metadata.db" ]]; then
  echo "No Calibre library found at: $LIBRARY_DIR"
  exit 1
fi

if pgrep -x calibre >/dev/null 2>&1; then
  echo "Calibre is open. Close the desktop app before making a snapshot."
  exit 1
fi

mkdir -p "$BACKUP_DIR"

if launchctl print "gui/$(id -u)/com.nicodotfiles.calibre-server" >/dev/null 2>&1; then
  server_was_loaded=true
  launchctl bootout "gui/$(id -u)" "$SERVER_PLIST"
fi

restart_server() {
  rm -f "$temporary_archive"
  if [[ "$server_was_loaded" == true ]] && [[ -f "$SERVER_PLIST" ]]; then
    launchctl bootstrap "gui/$(id -u)" "$SERVER_PLIST" >/dev/null 2>&1 || true
  fi
}
trap restart_server EXIT INT TERM

echo "Creating iCloud snapshot: $(basename "$archive")"
tar -czf "$temporary_archive" -C "$LIBRARY_DIR" .
mv "$temporary_archive" "$archive"
echo "Snapshot complete. iCloud will upload it in the background."
