#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/menu-ui.sh"
source "$DOTFILES_DIR/system-apps.conf"

# Voeg hier apps toe die systeemcomponenten installeren of sudo nodig hebben.
# Houd de volgorde van SYSTEM_CASKS en SYSTEM_LABELS gelijk.
configure_homebrew_for_current_shell() {
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    echo "Homebrew is niet gevonden. Voer eerst ./bootstrap.sh uit."
    exit 1
  fi
}

start_sudo_keepalive() {
  echo "Beheerdersrechten voorbereiden (eenmalig)..."
  sudo -v

  while sudo -n true; do
    sleep 60
  done 2>/dev/null &
  SUDO_KEEPALIVE_PID=$!

  trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT INT TERM
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Dit script is uitsluitend bedoeld voor macOS."
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  configure_homebrew_for_current_shell
fi

print_menu_header "Optional macOS system apps"

if [[ "${DOTFILES_INSTALL_ALL:-}" == "1" ]]; then
  selected=()
  for index in "${!SYSTEM_CASKS[@]}"; do
    selected+=("$((index + 1))")
  done
else
  for index in "${!SYSTEM_CASKS[@]}"; do
    printf '  %d) %s\n' "$((index + 1))" "${SYSTEM_LABELS[$index]}"
  done

  echo "  a) Alles installeren"
  echo "  q) Stoppen"
  echo
  read -r -p "Kies nummers (bijvoorbeeld 1 2), a of q: " selection

  case "$selection" in
    q|Q|"")
      echo "Geen systeemapps geïnstalleerd."
      exit 0
      ;;
    a|A)
      selected=()
      for index in "${!SYSTEM_CASKS[@]}"; do
        selected+=("$((index + 1))")
      done
      ;;
    *)
      IFS=', ' read -r -a selected <<< "$selection"
      ;;
  esac
fi

for choice in "${selected[@]}"; do
  if ! [[ "$choice" =~ ^[0-9]+$ ]] ||
     (( choice < 1 || choice > ${#SYSTEM_CASKS[@]} )); then
    echo "Ongeldige keuze: $choice"
    exit 1
  fi
done

echo
echo "This will install or update:"
for choice in "${selected[@]}"; do
  index=$((choice - 1))
  printf '  - %s\n' "${SYSTEM_LABELS[$index]}"
done

if ! confirm_action "Continue with system app installation?"; then
  echo "Cancelled."
  exit "$MENU_CANCELLED"
fi

start_sudo_keepalive

for choice in "${selected[@]}"; do
  index=$((choice - 1))
  echo
  run_with_progress "${SYSTEM_LABELS[$index]} installeren" \
    brew install --cask "${SYSTEM_CASKS[$index]}"
done

echo
echo "Gekozen systeemapps zijn verwerkt. Volg eventuele macOS- of vendor-dialoogvensters."
