#!/usr/bin/env bash

# Remove individually selected optional macOS apps. Core tooling is excluded.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

configure_homebrew_for_current_shell() {
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script is for macOS only."
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  configure_homebrew_for_current_shell
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is missing."
  exit 1
fi

entries=()

add_brewfile_entries() {
  local file="$1"
  local kind name

  while IFS='|' read -r kind name; do
    [[ -n "$name" ]] || continue
    if [[ "$kind" == "brew" ]] && brew list --formula "$name" >/dev/null 2>&1; then
      entries+=("formula|$name|$name")
    elif [[ "$kind" == "cask" ]] && brew list --cask "$name" >/dev/null 2>&1; then
      entries+=("cask|$name|$name")
    fi
  done < <(sed -nE 's/^(brew|cask) "([^"]+)".*/\1|\2/p' "$file")
}

add_brewfile_entries "$DOTFILES_DIR/Brewfile.dev"
add_brewfile_entries "$DOTFILES_DIR/Brewfile.personal"

if brew list --cask docker-desktop >/dev/null 2>&1; then
  entries+=("cask|docker-desktop|Docker Desktop")
fi

if command -v mas >/dev/null 2>&1; then
  mas_list="$(mas list 2>/dev/null || true)"
  for file in "$DOTFILES_DIR/Brewfile.mas" "$DOTFILES_DIR/Brewfile.office.mas"; do
    while IFS='|' read -r id name; do
      [[ -n "$id" ]] || continue
      if printf '%s\n' "$mas_list" | grep -q "^$id "; then
        entries+=("mas|$id|$name")
      fi
    done < <(sed -nE 's/^mas "([^"]+)", id: ([0-9]+).*/\2|\1/p' "$file")
  done
fi

if (( ${#entries[@]} == 0 )); then
  echo "No optional apps from this repository are installed."
  exit 0
fi

echo "Installed optional apps"
echo
for index in "${!entries[@]}"; do
  IFS='|' read -r kind _id label <<< "${entries[$index]}"
  printf '  %d) %-8s %s\n' "$((index + 1))" "$kind" "$label"
done

echo
read -r -p "Choose apps to uninstall (for example 1 3), or q to quit: " selection

case "$selection" in
  q|Q|"")
    echo "No apps removed."
    exit 0
    ;;
  *) IFS=', ' read -r -a selected <<< "$selection" ;;
esac

for choice in "${selected[@]}"; do
  if ! [[ "$choice" =~ ^[0-9]+$ ]] ||
     (( choice < 1 || choice > ${#entries[@]} )); then
    echo "Invalid choice: $choice"
    exit 1
  fi
done

echo
read -r -p "Remove the selected apps? [y/N] " confirmation
case "$confirmation" in
  y|Y|yes|YES|Yes) ;;
  *)
    echo "No apps removed."
    exit 0
    ;;
esac

for choice in "${selected[@]}"; do
  IFS='|' read -r kind id label <<< "${entries[$((choice - 1))]}"
  echo "Removing: $label"
  case "$kind" in
    formula) brew uninstall "$id" ;;
    cask) brew uninstall --cask "$id" ;;
    mas) mas uninstall "$id" ;;
  esac
done

echo "Selected apps have been removed."
