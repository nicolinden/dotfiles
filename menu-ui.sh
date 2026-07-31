#!/usr/bin/env bash

# Shared terminal presentation for the interactive dotfiles menus.
MENU_CANCELLED=20

print_menu_header() {
  local title="$1"

  if [[ -t 1 ]]; then
    clear
  fi

  printf '\n'
  printf '%s\n' '  ____        _    __ _ _           '
  printf '%s\n' ' |  _ \  ___ | |_ / _(_) | ___  ___ '
  printf '%s\n' ' | | | |/ _ \| __| |_| | |/ _ \/ __|'
  printf '%s\n' ' | |_| | (_) | |_|  _| | |  __/\__ \'
  printf '%s\n' ' |____/ \___/ \__|_| |_|_|\___||___/'
  printf '\n  %s\n\n' "$title"
}

wait_for_menu_return() {
  echo
  read -r -p "Press Enter to return to the menu..." _
}

confirm_action() {
  local prompt="${1:-Continue?}"
  local answer

  if [[ "${DOTFILES_ASSUME_YES:-}" == "1" ]]; then
    return 0
  fi

  echo
  read -r -p "$prompt [y/N] " answer
  [[ "$answer" =~ ^([yY]|[yY][eE][sS])$ ]]
}

show_brewfile_plan() {
  local brewfile="$1"

  sed -nE \
    -e 's/^brew "([^"]+)".*/  - \1/p' \
    -e 's/^cask "([^"]+)".*/  - \1/p' \
    "$brewfile"
}

show_mas_plan() {
  local brewfile="$1"

  sed -nE 's/^mas "([^"]+)", id: [0-9]+.*/  - \1/p' "$brewfile"
}
