#!/usr/bin/env bash

# Shared terminal presentation for the interactive dotfiles menus.
MENU_CANCELLED=20

run_with_progress() {
  local label="$1"
  shift

  # Houd normale uitvoer intact wanneer dit script niet interactief draait.
  if [[ ! -t 1 ]]; then
    "$@"
    return
  fi

  local log_file command_pid status position=0 direction=1 width=24 bar done_bar
  log_file="$(mktemp)"

  "$@" >"$log_file" 2>&1 &
  command_pid=$!

  while kill -0 "$command_pid" 2>/dev/null; do
    printf -v bar '%*s' "$width" ''
    bar="${bar// /─}"
    bar="${bar:0:position}●${bar:position+1}"
    printf '\r  %-34s [%s]' "$label" "$bar"

    if (( position == width - 1 )); then
      direction=-1
    elif (( position == 0 )); then
      direction=1
    fi
    position=$((position + direction))
    sleep 0.12
  done

  if wait "$command_pid"; then
    status=0
    printf -v done_bar '%*s' "$width" ''
    done_bar="${done_bar// /=}"
    printf '\r  %-34s [%s] klaar\n' "$label" "$done_bar"
  else
    status=$?
    printf '\r  %-34s [mislukt]\n' "$label"
    echo
    cat "$log_file"
  fi

  rm -f "$log_file"
  return "$status"
}

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
