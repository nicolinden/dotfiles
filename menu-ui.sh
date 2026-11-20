#!/usr/bin/env bash

# Shared terminal presentation for the interactive dotfiles menus.
MENU_CANCELLED=20
MENU_QUIT=21

# A child menu runs in its own process. Preserve a request to quit the entire
# manager while allowing callers to handle ordinary cancellation themselves.
run_menu_child() {
  local status
  if "$@"; then
    return 0
  else
    status=$?
  fi
  if (( status == MENU_QUIT )); then
    exit "$MENU_QUIT"
  fi
  return "$status"
}

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

app_bundle_installed() {
  local helper_dir="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
  python3 "$helper_dir/app-installed.py" "$1"
}

install_formula() {
  if brew list --formula "${1##*/}" >/dev/null 2>&1; then
    echo "Already installed; skipped: $1"
    return 0
  fi
  HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_UPGRADE=1 \
    caffeinate -i brew install "$1"
}

install_mas_app() {
  local app_id="$1" label="$2" installed
  installed="$(mas list 2>/dev/null)" || installed=""
  if printf '%s\n' "$installed" | awk -v id="$app_id" '$1 == id { found=1 } END { exit !found }' ||
     app_bundle_installed "$label"; then
    echo "Already installed; skipped: $label"
    return 0
  fi
  caffeinate -i mas install "$app_id"
}

install_cask() {
  local name="$1"
  if brew list --cask "${name##*/}" >/dev/null 2>&1; then
    echo "Already installed; skipped: $name"
    return 0
  fi
  case "$name" in
    codex)
      if command -v codex >/dev/null 2>&1; then echo "Already installed; skipped: Codex CLI"; return 0; fi
      ;;
    android-platform-tools)
      if command -v adb >/dev/null 2>&1; then echo "Already installed; skipped: Android platform tools"; return 0; fi
      ;;
    *)
      if app_bundle_installed "$name"; then
        echo "Already installed; skipped: $name"
        return 0
      fi
      ;;
  esac
  if [[ "$name" == "tailscale-app" ]] &&
     { [[ -e "/Applications/Tailscale.app/Contents/_MASReceipt/receipt" ]] ||
       [[ -e "$HOME/Applications/Tailscale.app/Contents/_MASReceipt/receipt" ]]; }; then
    echo "Tailscale from the Mac App Store is installed."
    echo "Remove that variant and restart macOS before installing standalone Tailscale."
    return 1
  fi
  HOMEBREW_CASK_OPTS="--appdir=/Applications" HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_UPGRADE=1 \
    caffeinate -i brew install --cask --appdir=/Applications "$name"
}

install_brewfile_items() {
  local brewfile="$1"
  local kinds=() names=() kind name total index current=0 failures=0

  while IFS='|' read -r kind name; do
    [[ -n "$kind" && -n "$name" ]] || continue
    kinds+=("$kind")
    names+=("$name")
  done < <(sed -nE \
    -e 's/^brew "([^"]+)".*/brew|\1/p' \
    -e 's/^cask "([^"]+)".*/cask|\1/p' \
    "$brewfile")

  total=${#names[@]}
  for index in "${!names[@]}"; do
    kind=${kinds[$index]}
    name=${names[$index]}
    current=$((current + 1))
    printf '\n[%d/%d] ● bezig: %s\n' "$current" "$total" "$name"

    if [[ "$kind" == "cask" ]]; then
      if ! install_cask "$name"; then
        printf '[%d/%d] ✗ mislukt: %s\n' "$current" "$total" "$name"
        failures=$((failures + 1))
        continue
      fi
    else
      if ! install_formula "$name"; then
        printf '[%d/%d] ✗ mislukt: %s\n' "$current" "$total" "$name"
        failures=$((failures + 1))
        continue
      fi
    fi

    printf '[%d/%d] ✓ klaar: %s\n' "$current" "$total" "$name"
  done
  (( failures == 0 ))
}

install_mas_items() {
  local brewfile="$1"
  local names=() ids=() name app_id total index current=0 failures=0

  while IFS='|' read -r name app_id; do
    [[ -n "$name" && -n "$app_id" ]] || continue
    names+=("$name")
    ids+=("$app_id")
  done < <(sed -nE 's/^mas "([^"]+)", id: ([0-9]+).*/\1|\2/p' "$brewfile")

  total=${#names[@]}
  for index in "${!names[@]}"; do
    name=${names[$index]}
    app_id=${ids[$index]}
    current=$((current + 1))
    printf '\n[%d/%d] ● bezig: %s\n' "$current" "$total" "$name"
    if ! install_mas_app "$app_id" "$name"; then
      printf '[%d/%d] ✗ mislukt: %s\n' "$current" "$total" "$name"
      failures=$((failures + 1))
      continue
    fi
    printf '[%d/%d] ✓ klaar: %s\n' "$current" "$total" "$name"
  done
  (( failures == 0 ))
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
  local line name label

  while IFS= read -r line; do
    name="$(printf '%s\n' "$line" | sed -nE \
      -e 's/^brew "([^"]+)".*/\1/p' \
      -e 's/^cask "([^"]+)".*/\1/p')"
    [[ -n "$name" ]] || continue

    label="$(printf '%s\n' "$line" \
      | sed -nE 's/.*#[[:space:]]*label:[[:space:]]*(.*)$/\1/p')"
    printf '  - %s\n' "${label:-$name}"
  done < "$brewfile"
}

show_mas_plan() {
  local brewfile="$1"

  sed -nE 's/^mas "([^"]+)", id: [0-9]+.*/  - \1/p' "$brewfile"
}
