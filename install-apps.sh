#!/usr/bin/env bash

# Install optional macOS app profiles after bootstrap, or on an existing Mac.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

configure_homebrew_for_current_shell() {
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_brewfile() {
  local file="$1"
  local label="$2"

  echo
  echo "Installing: $label"
  HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications" \
    caffeinate -i brew bundle install --file="$DOTFILES_DIR/$file"
}

brewfile_status() {
  local file="$1"
  local kind name total=0 installed=0

  while IFS='|' read -r kind name; do
    [[ -n "$name" ]] || continue
    total=$((total + 1))
    if [[ "$kind" == "brew" ]] && brew list --formula "$name" >/dev/null 2>&1; then
      installed=$((installed + 1))
    elif [[ "$kind" == "cask" ]] && brew list --cask "$name" >/dev/null 2>&1; then
      installed=$((installed + 1))
    fi
  done < <(sed -nE 's/^(brew|cask) "([^"]+)".*/\1|\2/p' "$DOTFILES_DIR/$file")

  printf '%d/%d installed' "$installed" "$total"
}

mas_brewfile_status() {
  local file="$1"
  local id total=0 installed=0
  local mas_list

  if ! command -v mas >/dev/null 2>&1; then
    printf 'mas unavailable'
    return
  fi

  mas_list="$(mas list 2>/dev/null || true)"
  while IFS= read -r id; do
    [[ -n "$id" ]] || continue
    total=$((total + 1))
    if printf '%s\n' "$mas_list" | grep -q "^$id "; then
      installed=$((installed + 1))
    fi
  done < <(sed -nE 's/^mas "[^"]+", id: ([0-9]+).*/\1/p' "$DOTFILES_DIR/$file")

  printf '%d/%d installed' "$installed" "$total"
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script is for macOS only."
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  configure_homebrew_for_current_shell
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is missing. Run ./bootstrap.sh first."
  exit 1
fi

mkdir -p "$HOME/Applications"

echo "Optional app profiles"
echo
printf '  1) %-55s [%s]\n' "Core and window management" "$(brewfile_status Brewfile)"
printf '  2) %-55s [%s]\n' "Development (VS Code, WezTerm, Bruno, LazyGit, ... )" "$(brewfile_status Brewfile.dev)"
printf '  3) %-55s [%s]\n' "Personal apps (communication, design, files)" "$(brewfile_status Brewfile.personal)"
printf '  4) %-55s [%s]\n' "Personal Mac App Store apps" "$(mas_brewfile_status Brewfile.mas)"
printf '  5) %-55s [%s]\n' "Office and iWork from the Mac App Store" "$(mas_brewfile_status Brewfile.office.mas)"
if brew list --cask docker-desktop >/dev/null 2>&1; then
  system_status="installed"
else
  system_status="not installed"
fi
printf '  6) %-55s [%s]\n' "System apps (Docker Desktop)" "$system_status"
echo "  a) Install everything"
echo "  q) Quit"
echo
read -r -p "Choose one or more numbers (for example 2 3), a or q: " selection

case "$selection" in
  q|Q|"")
    echo "No apps installed."
    exit 0
    ;;
  a|A)
    selected=(1 2 3 4 5 6)
    ;;
  *)
    IFS=', ' read -r -a selected <<< "$selection"
    ;;
esac

for choice in "${selected[@]}"; do
  if ! [[ "$choice" =~ ^[1-6]$ ]]; then
    echo "Invalid choice: $choice"
    exit 1
  fi
done

for choice in "${selected[@]}"; do
  case "$choice" in
    1) install_brewfile "Brewfile" "core and window management" ;;
    2) install_brewfile "Brewfile.dev" "development" ;;
    3) install_brewfile "Brewfile.personal" "personal apps" ;;
    4) "$DOTFILES_DIR/install-mac-apps.sh" ;;
    5) "$DOTFILES_DIR/office-installer.sh" ;;
    6) "$DOTFILES_DIR/install-system-apps.sh" ;;
  esac
done

echo
echo "Selected app profiles have been processed."
