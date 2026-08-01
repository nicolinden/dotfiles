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

install_brewfile_items() {
  local brewfile="$1"
  local app_dir="$2"
  local kinds=() names=() kind name total index current=0

  while IFS=$'\t' read -r kind name; do
    [[ -n "$kind" && -n "$name" ]] || continue
    kinds+=("$kind")
    names+=("$name")
  done < <(sed -nE \
    -e 's/^brew "([^"]+)".*/brew\t\1/p' \
    -e 's/^cask "([^"]+)".*/cask\t\1/p' \
    "$brewfile")

  total=${#names[@]}
  for index in "${!names[@]}"; do
    kind=${kinds[$index]}
    name=${names[$index]}
    current=$((current + 1))
    printf '\n[%d/%d] ● bezig: %s\n' "$current" "$total" "$name"

    if [[ "$kind" == "cask" ]]; then
      if ! HOMEBREW_CASK_OPTS="--appdir=$app_dir" \
        caffeinate -i brew install --cask "$name"; then
        printf '[%d/%d] ✗ mislukt: %s\n' "$current" "$total" "$name"
        return 1
      fi
    else
      if ! caffeinate -i brew install "$name"; then
        printf '[%d/%d] ✗ mislukt: %s\n' "$current" "$total" "$name"
        return 1
      fi
    fi

    printf '[%d/%d] ✓ klaar: %s\n' "$current" "$total" "$name"
  done
}

install_mas_items() {
  local brewfile="$1"
  local names=() ids=() name app_id total index current=0

  while IFS=$'\t' read -r name app_id; do
    [[ -n "$name" && -n "$app_id" ]] || continue
    names+=("$name")
    ids+=("$app_id")
  done < <(sed -nE 's/^mas "([^"]+)", id: ([0-9]+).*/\1\t\2/p' "$brewfile")

  total=${#names[@]}
  for index in "${!names[@]}"; do
    name=${names[$index]}
    app_id=${ids[$index]}
    current=$((current + 1))
    printf '\n[%d/%d] ● bezig: %s\n' "$current" "$total" "$name"
    if ! caffeinate -i mas install "$app_id"; then
      printf '[%d/%d] ✗ mislukt: %s\n' "$current" "$total" "$name"
      return 1
    fi
    printf '[%d/%d] ✓ klaar: %s\n' "$current" "$total" "$name"
  done
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
