#!/usr/bin/env bash

# Inventory is read-only unless --manage is explicitly selected.
set -euo pipefail
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ "$(uname -s)" == Darwin ]] || { echo "This script is for macOS only."; exit 1; }
case "${1:-}" in ""|--manage) ;; *) echo "Usage: ./audit-apps.sh [--manage]"; exit 1 ;; esac
if ! command -v brew >/dev/null 2>&1; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi
exec python3 "$DOTFILES_DIR/audit-apps.py" "$DOTFILES_DIR" "$(brew --prefix)" "$@"
