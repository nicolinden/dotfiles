#!/usr/bin/env bash

# Configure this Mac as the Calibre library master or as a browser client.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="$HOME/.config/dotfiles"
ROLE_FILE="$STATE_DIR/calibre-role"
URL_FILE="$STATE_DIR/calibre-url"
LIBRARY_DIR="${CALIBRE_LIBRARY_DIR:-$HOME/Calibre Library}"
ICLOUD_ROOT="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
BACKUP_DIR="${CALIBRE_BACKUP_DIR:-$ICLOUD_ROOT/Calibre Backups}"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
SERVER_PLIST="$LAUNCH_AGENTS_DIR/com.nicodotfiles.calibre-server.plist"
BACKUP_PLIST="$LAUNCH_AGENTS_DIR/com.nicodotfiles.calibre-backup.plist"

find_calibre_server() {
  local candidate
  for candidate in \
    "$HOME/Applications/calibre.app/Contents/MacOS/calibre-server" \
    "/Applications/calibre.app/Contents/MacOS/calibre-server"; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

write_server_agent() {
  local server_binary="$1"
  mkdir -p "$LAUNCH_AGENTS_DIR" "$HOME/Library/Logs"
  cat >"$SERVER_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.nicodotfiles.calibre-server</string>
  <key>ProgramArguments</key><array>
    <string>$server_binary</string><string>--port</string><string>8080</string><string>$LIBRARY_DIR</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>$HOME/Library/Logs/calibre-server.log</string>
  <key>StandardErrorPath</key><string>$HOME/Library/Logs/calibre-server.log</string>
</dict></plist>
EOF
}

write_backup_agent() {
  mkdir -p "$LAUNCH_AGENTS_DIR" "$HOME/Library/Logs"
  cat >"$BACKUP_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.nicodotfiles.calibre-backup</string>
  <key>ProgramArguments</key><array>
    <string>$DOTFILES_DIR/calibre-backup.sh</string>
  </array>
  <key>StartCalendarInterval</key><dict>
    <key>Hour</key><integer>3</integer><key>Minute</key><integer>15</integer>
  </dict>
  <key>StandardOutPath</key><string>$HOME/Library/Logs/calibre-backup.log</string>
  <key>StandardErrorPath</key><string>$HOME/Library/Logs/calibre-backup.log</string>
</dict></plist>
EOF
}

unload_agent() {
  local plist="$1"
  launchctl bootout "gui/$(id -u)" "$plist" >/dev/null 2>&1 || true
}

load_agent() {
  local plist="$1"
  unload_agent "$plist"
  launchctl bootstrap "gui/$(id -u)" "$plist"
}

restore_latest_backup_if_needed() {
  local latest
  if [[ -e "$LIBRARY_DIR/metadata.db" ]]; then
    echo "Existing master library retained: $LIBRARY_DIR"
    return
  fi

  mkdir -p "$BACKUP_DIR"
  latest="$(find "$BACKUP_DIR" -maxdepth 1 -type f -name 'calibre-library-*.tar.gz' -print 2>/dev/null | sort | tail -n 1)"
  if [[ -z "$latest" ]]; then
    mkdir -p "$LIBRARY_DIR"
    echo "No iCloud backup found; Calibre will create a new library."
    return
  fi

  echo "Restoring the latest iCloud snapshot: $(basename "$latest")"
  mkdir -p "$LIBRARY_DIR"
  tar -xzf "$latest" -C "$LIBRARY_DIR"
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Calibre setup is available on macOS only."
  exit 1
fi

server_binary="$(find_calibre_server || true)"
if [[ -z "$server_binary" ]]; then
  echo "Calibre is not installed. Install the personal apps first."
  exit 1
fi

mkdir -p "$STATE_DIR"
echo
echo "How should this Mac use Calibre?"
echo "  1) Master — owns the library and runs the Content Server"
echo "  2) Client — opens the library from the master"
echo "  k) Keep the existing role"
read -r -p "Choose an option: " choice

case "$choice" in
  1)
    printf 'master\n' >"$ROLE_FILE"
    restore_latest_backup_if_needed
    write_server_agent "$server_binary"
    write_backup_agent
    load_agent "$SERVER_PLIST"
    load_agent "$BACKUP_PLIST"
    echo
    echo "This Mac is configured as the Calibre master."
    echo "Library: $LIBRARY_DIR"
    echo "iCloud snapshots: $BACKUP_DIR"
    echo "Content Server: http://$(scutil --get LocalHostName 2>/dev/null || hostname):8080"
    echo "Run ./calibre-backup.sh after important library changes."
    ;;
  2)
    printf 'client\n' >"$ROLE_FILE"
    unload_agent "$SERVER_PLIST"
    unload_agent "$BACKUP_PLIST"
    read -r -p "Master URL [http://calibre-master.local:8080]: " master_url
    master_url="${master_url:-http://calibre-master.local:8080}"
    printf '%s\n' "$master_url" >"$URL_FILE"
    echo
    echo "This Mac is configured as a Calibre client."
    echo "Open the library at: $master_url"
    ;;
  k|K|"")
    if [[ -f "$ROLE_FILE" ]]; then
      echo "Existing Calibre role retained: $(<"$ROLE_FILE")"
    else
      echo "No Calibre role has been configured yet."
    fi
    ;;
  *)
    echo "Invalid choice."
    exit 1
    ;;
esac
