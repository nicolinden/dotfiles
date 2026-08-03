#!/usr/bin/env bash

# Back up SSH keys as encrypted archives and install the Calibre sync key.
set -euo pipefail

STATE_DIR="$HOME/.config/dotfiles"
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/menu-ui.sh"
CONFIG_FILE="$STATE_DIR/calibre-sync.conf"
DEFAULT_SERVER="server.nokionline.com"
FALLBACK_SERVER="10.10.2.2"
DEFAULT_BACKUP_DIR=".local/share/dotfiles-ssh-backups"
CALIBRE_SSH_KEY="$HOME/.ssh/noki-server"

die() { echo "Error: $*" >&2; exit 1; }

load_server() {
  [[ -f "$CONFIG_FILE" ]] || die "Configure Calibre sync first so the server is known."
  # shellcheck disable=SC1090
source "$CONFIG_FILE"
if [[ -n "${BACKUP_ROOT:-}" ]]; then DEFAULT_BACKUP_DIR="$BACKUP_ROOT/dotfiles-ssh-backups"; fi
  [[ -n "${CALIBRE_SYNC_SERVER:-}" ]] || die "Configure Calibre sync first so the server is known."
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
  local ssh_command="ssh -i $CALIBRE_SSH_KEY -o IdentitiesOnly=yes"
  [[ -n "${NOKI_AGENT_SOCKET:-}" ]] && ssh_command+=" -o IdentityAgent=$NOKI_AGENT_SOCKET"
  rsync -e "$ssh_command" "$@"
}

load_noki_key_once() {
  [[ -n "${NOKI_AGENT_SOCKET:-}" ]] && return
  eval "$(ssh-agent -s)" >/dev/null
  NOKI_AGENT_SOCKET="$SSH_AUTH_SOCK"
  ssh-add "$CALIBRE_SSH_KEY" >/dev/null
}

show_server_space() {
  calibre_ssh "$CALIBRE_SYNC_ACTIVE_SERVER" "df -Pm . | awk 'NR==2 {print \$4}'" | xargs -I{} echo "Server space available: {} MB"
}

choose_server() {
  CALIBRE_SYNC_ACTIVE_SERVER="$CALIBRE_SYNC_SERVER"
  if calibre_ssh -o ConnectTimeout=5 "$CALIBRE_SYNC_ACTIVE_SERVER" true; then
    return
  fi
  if [[ "$CALIBRE_SYNC_SERVER" == "$DEFAULT_SERVER" ]] && \
     calibre_ssh -o ConnectTimeout=5 "$FALLBACK_SERVER" true; then
    CALIBRE_SYNC_ACTIVE_SERVER="$FALLBACK_SERVER"
    echo "Using local server fallback: $FALLBACK_SERVER"
    return
  fi
  die "Cannot connect with the Noki server SSH key. Install it on the server first."
}

install_calibre_key() {
  local target key_comment
  load_server
  if [[ ! -f "$CALIBRE_SSH_KEY.pub" ]]; then
    command -v ssh-keygen >/dev/null 2>&1 || die "ssh-keygen is not available."
    mkdir -p "$HOME/.ssh"
    key_comment="noki-server-$(hostname -s 2>/dev/null || hostname)"
    echo "Creating a separate Noki server SSH key for this Mac."
    ssh-keygen -t ed25519 -N '' -f "$CALIBRE_SSH_KEY" -C "$key_comment"
  fi
  target="$CALIBRE_SYNC_SERVER"
  if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$target" true >/dev/null 2>&1 && \
     [[ "$CALIBRE_SYNC_SERVER" == "$DEFAULT_SERVER" ]]; then
    target="$FALLBACK_SERVER"
  fi
  echo "Enter the server password once to authorize this Mac's Noki server key."
  ssh-copy-id -i "$CALIBRE_SSH_KEY.pub" -o IdentitiesOnly=yes "$target"
  echo "Noki server SSH key installed. Future backups and restores need no server password."
}

valid_name() {
  [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$ ]]
}

backup_ssh_folder() {
  local name default_name temp_dir archive encrypted
  load_server
  [[ -d "$HOME/.ssh" ]] || die "No .ssh folder exists on this Mac."
  command -v openssl >/dev/null 2>&1 || die "openssl is not available."
  load_noki_key_once
  choose_server
  default_name="macbook-$(date '+%Y-%m-%d')"
  read -r -p "Backup name [$default_name]: " name
  name="${name:-$default_name}"
  valid_name "$name" || die "Use 1–64 letters, numbers, dots, underscores or hyphens."
  if calibre_ssh "$CALIBRE_SYNC_ACTIVE_SERVER" "test ! -e '$DEFAULT_BACKUP_DIR/$name.tar.gz.enc'"; then
    :
  else
    die "A backup named '$name' already exists. Choose a different name."
  fi
  temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-ssh-backup.XXXXXX")"
  archive="$temp_dir/$name.tar.gz"
  encrypted="$archive.enc"
  trap "rm -rf '$temp_dir'" EXIT
  # The local 1Password SSH agent is a socket, not key material, and cannot
  # be archived. It is recreated automatically when 1Password starts.
  tar --exclude='.ssh/agent' -czf "$archive" -C "$HOME" .ssh
  echo "Choose an encryption password for this backup; it is required for restoration."
  openssl enc -aes-256-cbc -salt -pbkdf2 -in "$archive" -out "$encrypted"
  calibre_ssh "$CALIBRE_SYNC_ACTIVE_SERVER" "mkdir -p '$DEFAULT_BACKUP_DIR'"
  show_server_space
  calibre_rsync --progress "$encrypted" "$CALIBRE_SYNC_ACTIVE_SERVER:$DEFAULT_BACKUP_DIR/$name.tar.gz.enc"
  echo "Encrypted SSH backup uploaded as: $name"
}

list_backups() {
  local backups
  load_server
  load_noki_key_once
  choose_server
  echo "Available encrypted SSH backups:"
  backups="$(calibre_ssh "$CALIBRE_SYNC_ACTIVE_SERVER" "find '$DEFAULT_BACKUP_DIR' -maxdepth 1 -type f -name '*.tar.gz.enc' -print 2>/dev/null | sed 's#.*/##; s#\\.tar\\.gz\\.enc##' | sort")"
  if [[ -z "$backups" ]]; then
    echo "  No SSH backups have been uploaded yet. Choose option 2 to create one."
  else
    printf '%s\n' "$backups"
  fi
}

restore_ssh_folder() {
  local name temp_dir encrypted archive local_backup_dir local_backup confirm
  load_server
  command -v openssl >/dev/null 2>&1 || die "openssl is not available."
  load_noki_key_once
  choose_server
  read -r -p "Backup name to restore: " name
  valid_name "$name" || die "Invalid backup name."
  temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-ssh-restore.XXXXXX")"
  encrypted="$temp_dir/$name.tar.gz.enc"
  archive="$temp_dir/$name.tar.gz"
  trap "rm -rf '$temp_dir'" EXIT
  show_server_space
  calibre_rsync --progress "$CALIBRE_SYNC_ACTIVE_SERVER:$DEFAULT_BACKUP_DIR/$name.tar.gz.enc" "$encrypted" \
    || die "Backup '$name' was not found on the server."
  echo "Enter the encryption password used when this backup was made."
  openssl enc -d -aes-256-cbc -pbkdf2 -in "$encrypted" -out "$archive"
  tar -tzf "$archive" | grep -qx '.ssh/' || die "Invalid SSH backup archive."
  echo
  echo "This replaces the current ~/.ssh folder with backup '$name'."
  read -r -p "Continue? [y/N] " confirm
  [[ "$confirm" =~ ^([yY]|[yY][eE][sS])$ ]] || { echo "Cancelled."; return; }
  local_backup_dir="$HOME/.ssh-backups"
  mkdir -p "$local_backup_dir"
  local_backup="$local_backup_dir/ssh-before-restore-$(date -u '+%Y%m%dT%H%M%SZ').tar.gz"
  if [[ -d "$HOME/.ssh" ]]; then
    tar --exclude='.ssh/agent' -czf "$local_backup" -C "$HOME" .ssh
    echo "Current SSH settings saved locally as: $local_backup"
  fi
  rm -rf "$HOME/.ssh"
  tar -xzf "$archive" -C "$HOME"
  chmod 700 "$HOME/.ssh"
  find "$HOME/.ssh" -type f -name 'id_*' -exec chmod 600 {} +
  echo "SSH settings restored to ~/.ssh"
}

while true; do
  print_menu_header "SSH key backup and recovery"
  echo "  1) Create and install this Mac's Noki server SSH key"
  echo "  2) Create encrypted .ssh backup"
  echo "  3) List server backups"
  echo "  4) Restore a backup and replace local ~/.ssh"
  echo "  b) Back"
  echo
  read -r -p "Choose an option: " choice
  case "$choice" in
    1) ( install_calibre_key ) || true; wait_for_menu_return ;;
    2) ( backup_ssh_folder ) || true; wait_for_menu_return ;;
    3) ( list_backups ) || true; wait_for_menu_return ;;
    4) ( restore_ssh_folder ) || true; wait_for_menu_return ;;
    b|B|"") exit 0 ;;
    *) echo "Invalid choice." ;;
  esac
done
