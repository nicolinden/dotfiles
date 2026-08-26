#!/usr/bin/env bash

# Open the server-side SAP HANA menu without installing SAP tooling locally.
set -euo pipefail

readonly CONFIG_FILE="$HOME/.config/dotfiles/calibre-sync.conf"
readonly SSH_KEY="$HOME/.ssh/noki-server"
server="server.nokionline.com"

if [[ -r "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
  server="${CALIBRE_SYNC_SERVER:-$server}"
fi

ssh_args=(-t)
if [[ -f "$SSH_KEY" ]]; then
  ssh_args+=(-i "$SSH_KEY" -o IdentitiesOnly=yes)
  if [[ -n "${NOKI_AGENT_SOCKET:-}" ]]; then
    ssh_args+=(-o "IdentityAgent=$NOKI_AGENT_SOCKET")
  fi
fi

echo "Opening the SAP HANA Trial menu on ${server}..."
exec ssh "${ssh_args[@]}" "$server" \
  'cd "$HOME/dotfiles" && exec ./sap-hana-manager.sh'
