#!/usr/bin/env bash

# Standard apps, optional work apps and hardware drivers share one install menu.
set -euo pipefail
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/menu-ui.sh"

if [[ "$(uname -s)" != Darwin ]]; then
  echo "This script is for macOS only."
  exit 1
fi
if ! command -v brew >/dev/null 2>&1; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    echo "Homebrew is missing. Run ./setup.sh first."
    exit 1
  fi
fi

install_profiles() {
  local failures=0 profile file
  local brewfiles=() masfiles=() include_base=false include_work=false
  for profile in "$@"; do
    case "$profile" in
      1) brewfiles+=(Brewfile Brewfile.daily); masfiles+=(Brewfile.mas); include_base=true ;;
      2) include_work=true ;;
      3) brewfiles+=(Brewfile.personal); masfiles+=(Brewfile.personal.mas) ;;
      4) brewfiles+=(Brewfile.dev) ;;
    esac
  done
  print_menu_header "Confirm package installation"
  echo "Only missing apps will be installed. Existing apps are skipped."
  for file in ${brewfiles[@]+"${brewfiles[@]}"}; do show_brewfile_plan "$DOTFILES_DIR/$file"; done
  for file in ${masfiles[@]+"${masfiles[@]}"}; do show_mas_plan "$DOTFILES_DIR/$file"; done
  if [[ "$include_base" == true ]] && ! app_bundle_installed "Razer Synapse"; then
    echo "  - Razer Synapse (official installer)"
  fi
  if [[ "$include_work" == true ]]; then
    show_brewfile_plan "$DOTFILES_DIR/Brewfile.office"
    show_mas_plan "$DOTFILES_DIR/Brewfile.office.mas"
  fi
  echo "App Store sign-in and macOS permissions may still need your input."
  if ! confirm_action "Install these packages?"; then return "$MENU_CANCELLED"; fi
  local DOTFILES_ASSUME_YES=1 DOTFILES_INSTALL_ALL=1
  export DOTFILES_ASSUME_YES DOTFILES_INSTALL_ALL
  for file in ${brewfiles[@]+"${brewfiles[@]}"}; do
    if ! install_brewfile_items "$DOTFILES_DIR/$file"; then failures=$((failures + 1)); fi
  done
  for file in ${masfiles[@]+"${masfiles[@]}"}; do
    if ! install_mas_items "$DOTFILES_DIR/$file"; then failures=$((failures + 1)); fi
  done
  if [[ "$include_base" == true ]]; then
    if ! app_bundle_installed "Razer Synapse"; then
      if ! "$DOTFILES_DIR/vendor-apps.sh" razer; then failures=$((failures + 1)); fi
    fi

  fi
  if [[ "$include_work" == true ]]; then
    if ! "$DOTFILES_DIR/office-installer.sh"; then failures=$((failures + 1)); fi
  fi
  if (( failures > 0 )); then
    echo "$failures installation group(s) need attention. See the errors above."
    return 1
  fi
  echo "Selected packages completed. Use Backup / restore if you need your Calibre library."
}

run_install_submenu() {
  local status
  if run_menu_child "$@"; then
    wait_for_menu_return
  else
    status=$?
    (( status == MENU_CANCELLED )) || return "$status"
  fi
}

while true; do
  print_menu_header "Install apps"
  echo "  1) Basis (daily apps, WhatsApp, Tailscale, Codex CLI and Razer)"
  echo "  2) Work (install all or choose individual apps)"
  echo "  3) Personal (Calibre, DaisyDisk, iWork, Goodnotes, Pixelmator, Unarchiver)"
  echo "  4) Development / design (including Figma and Sketch)"
  echo "  b) Back"
  echo "  q) Quit"
  echo
  echo "Choose one package or several together, for example: 1 3 4"
  read -r -p "Choose packages: " selection
  case "$selection" in
    b|B|"") exit 0 ;;
    q|Q) exit "$MENU_QUIT" ;;
    2) run_install_submenu "$DOTFILES_DIR/office-installer.sh"; continue ;;
  esac
  selected=()
  seen=" "
  IFS=', ' read -r -a choices <<< "$selection"
  valid=true
  for choice in "${choices[@]}"; do
    if ! [[ "$choice" =~ ^[1-4]$ ]]; then valid=false; break; fi
    case "$seen" in *" $choice "*) ;; *) selected+=("$choice"); seen="$seen$choice " ;; esac
  done
  if [[ "$valid" != true ]] || (( ${#selected[@]} == 0 )); then
    echo "Invalid selection. Choose package numbers 1 to 4."
    wait_for_menu_return
    continue
  fi
  if install_profiles "${selected[@]}"; then
    wait_for_menu_return
  else
    status=$?
    (( status == MENU_CANCELLED )) || exit "$status"
  fi
done
