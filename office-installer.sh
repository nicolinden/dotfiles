#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/menu-ui.sh"

configure_homebrew_for_current_shell() {
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Dit script is uitsluitend bedoeld voor macOS."
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  configure_homebrew_for_current_shell
fi

print_menu_header "Work apps"
entries=()
while IFS='|' read -r kind id label; do
  [[ -n "$id" ]] && entries+=("$kind|$id|$label")
done < <(
  sed -nE 's/^mas "([^"]+)", id: ([0-9]+).*/mas|\2|\1/p' "$DOTFILES_DIR/Brewfile.office.mas"
  sed -nE 's/^cask "([^"]+)".*#[[:space:]]*label:[[:space:]]*(.*)$/cask|\1|\2/p' "$DOTFILES_DIR/Brewfile.office"
)

if [[ "${DOTFILES_INSTALL_ALL:-}" == "1" ]]; then
  selection=a
else
  for index in "${!entries[@]}"; do
    IFS='|' read -r kind id label <<< "${entries[$index]}"
    printf '  %d) %s\n' "$((index + 1))" "$label"
  done
  echo "  c) Citrix / Caffeinated automation"
  echo "  a) Install all work apps"
  echo "  b) Back"
  echo "  q) Quit"
  read -r -p "Choose apps (for example 1 3), a, b or q: " selection
fi

selected=()
case "$selection" in
  c|C)
    "$DOTFILES_DIR/citrix-caffeinated-manager.sh"
    exit 0
    ;;
  a|A)
    for index in "${!entries[@]}"; do selected+=("$((index + 1))"); done
    ;;
  b|B|"") exit "$MENU_CANCELLED" ;;
  q|Q) exit "$MENU_QUIT" ;;
  *) IFS=', ' read -r -a selected <<< "$selection" ;;
esac

if (( ${#selected[@]} == 0 )); then
  echo "No work apps selected."
  exit "$MENU_CANCELLED"
fi
displaylink_selected=false
for choice in "${selected[@]}"; do
  if ! [[ "$choice" =~ ^[1-9][0-9]*$ ]] ||
     (( choice > ${#entries[@]} )); then
    echo "Invalid choice: $choice"
    exit 1
  fi
  IFS='|' read -r kind id label <<< "${entries[$((choice - 1))]}"
  [[ "$id" != displaylink ]] || displaylink_selected=true
  printf '  - %s\n' "$label"
  if [[ "$kind" == mas ]] && ! command -v mas >/dev/null 2>&1; then
    echo "Mac App Store tooling is missing. Run ./bootstrap.sh first."
    exit 1
  fi
done

if ! confirm_action "Install the selected work apps?"; then
  exit "$MENU_CANCELLED"
fi

failures=0
for choice in "${selected[@]}"; do
  IFS='|' read -r kind id label <<< "${entries[$((choice - 1))]}"
  echo "Installing: $label"
  if [[ "$kind" == mas ]]; then
    if ! install_mas_app "$id" "$label"; then
      echo "Failed: $label (check your Mac App Store sign-in)."
      failures=$((failures + 1))
    fi
  elif ! install_cask "$id"; then
    echo "Failed: $label"
    failures=$((failures + 1))
  fi
done
if (( failures > 0 )); then
  echo "$failures work app(s) could not be installed."
  exit 1
fi
echo "Selected automatic work app installations completed. Sign in to Microsoft apps as needed."
if [[ "$displaylink_selected" == true ]]; then
  echo "For DisplayLink, allow Screen Recording in System Settings and restart when requested."
fi
