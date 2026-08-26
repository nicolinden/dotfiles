#!/usr/bin/env bash

# Keep the non-secret Noki server SSH settings in sync while preserving local hosts.
set -euo pipefail

readonly SSH_DIR="$HOME/.ssh"
readonly SSH_CONFIG="$SSH_DIR/config"
readonly START_MARKER="# BEGIN DOTFILES NOKI SERVER"
readonly END_MARKER="# END DOTFILES NOKI SERVER"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
tmp_file="$(mktemp "$SSH_DIR/config.tmp.XXXXXX")"
trap 'rm -f "$tmp_file"' EXIT

{
  printf '%s\n' "$START_MARKER"
  cat <<'EOF'
Host noki-server server.nokionline.com
  HostName server.nokionline.com
  User nico
  IdentityFile ~/.ssh/noki-server
  IdentitiesOnly yes
  AddKeysToAgent yes
  UseKeychain yes
EOF
  printf '%s\n\n' "$END_MARKER"
  if [[ -f "$SSH_CONFIG" ]]; then
    awk -v start="$START_MARKER" -v end="$END_MARKER" '
      $0 == start { skip=1; next }
      $0 == end { skip=0; next }
      !skip { print }
    ' "$SSH_CONFIG"
  fi
} >"$tmp_file"

chmod 600 "$tmp_file"
mv "$tmp_file" "$SSH_CONFIG"
trap - EXIT
echo "Noki server SSH configuration applied."
