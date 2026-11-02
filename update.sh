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
  echo "Dit updatescript is uitsluitend bedoeld voor macOS."
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  configure_homebrew_for_current_shell
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is niet geïnstalleerd."
  exit 1
fi

update_kinds=()
update_ids=()
update_labels=()

collect_homebrew_updates() {
  local kind="$1"
  local output="$2"
  local line name

  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    name="${line%% *}"
    [[ -n "$name" ]] || continue
    update_kinds+=("brew-$kind")
    update_ids+=("$name")
    update_labels+=("$name")
  done < <(printf '%s\n' "$output")
}

echo "Updateoverzichten ophalen..."
brew update
brew_formula_updates="$(brew outdated --formula --verbose || true)"
brew_cask_updates="$(brew outdated --cask --verbose || true)"
collect_homebrew_updates "formula" "$brew_formula_updates"
collect_homebrew_updates "cask" "$brew_cask_updates"
brew_updates="$(printf '%s\n%s\n' "$brew_formula_updates" "$brew_cask_updates" | sed '/^[[:space:]]*$/d')"
mas_updates=""
mas_error=""
if command -v mas >/dev/null 2>&1; then
  if mas_updates="$(mas outdated 2>&1)"; then
    :
  else
    mas_error="$mas_updates"
    mas_updates=""
  fi
fi

if [[ -n "$mas_updates" ]]; then
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    app_id="${line%%[[:space:]]*}"
    [[ "$app_id" =~ ^[0-9]+$ ]] || continue
    label="$(printf '%s\n' "$line" | sed -E 's/^[0-9]+[[:space:]]+//')"
    update_kinds+=("mas")
    update_ids+=("$app_id")
    update_labels+=("$label")
  done < <(printf '%s\n' "$mas_updates")
fi

echo
if [[ -n "$brew_updates" ]]; then
  echo "Homebrew-updates:"
  printf '%s\n' "$brew_updates"
else
  echo "Geen Homebrew-updates beschikbaar."
fi

if [[ -n "$mas_updates" ]]; then
  echo
  echo "Mac App Store-updates:"
  printf '%s\n' "$mas_updates"
elif [[ -n "$mas_error" ]]; then
  echo
  echo "Mac App Store-updates konden niet worden gecontroleerd:"
  printf '%s\n' "$mas_error"
elif command -v mas >/dev/null 2>&1; then
  echo "Geen Mac App Store-updates beschikbaar."
else
  echo "mas ontbreekt; Mac App Store-updates zijn overgeslagen."
fi

total_updates=${#update_ids[@]}
if (( total_updates == 0 )); then
  echo
  echo "Er zijn geen gevonden updates om te installeren."
  exit 0
fi

if ! confirm_action "Wil je de gevonden updates installeren?"; then
  echo "Updates overgeslagen."
  exit "$MENU_CANCELLED"
fi

echo
current_update=0
printf 'Ik verwerk %d updates één voor één.\n' "$total_updates"
for index in "${!update_ids[@]}"; do
  current_update=$((current_update + 1))
  remaining_updates=$((total_updates - current_update))
  kind="${update_kinds[$index]}"
  app_id="${update_ids[$index]}"
  label="${update_labels[$index]}"

  printf '\n[%d/%d] ● bezig: %s — nog %d\n' \
    "$current_update" "$total_updates" "$label" "$remaining_updates"

  case "$kind" in
    brew-formula)
      formula_prefix="$(brew --prefix "$app_id")"
      if [[ -L "$formula_prefix" && ! -e "$formula_prefix" ]]; then
        echo "Homebrew-link voor $app_id is kapot; formule opnieuw installeren om de link te herstellen."
        if ! caffeinate -i brew reinstall "$app_id"; then
          printf '[%d/%d] ✗ herstel mislukt: %s. De resterende %d updates zijn overgeslagen.\n' \
            "$current_update" "$total_updates" "$label" "$remaining_updates" >&2
          exit 1
        fi
      elif ! caffeinate -i brew upgrade --formula "$app_id"; then
        printf '[%d/%d] ✗ mislukt: %s. De resterende %d updates zijn overgeslagen.\n' \
          "$current_update" "$total_updates" "$label" "$remaining_updates" >&2
        exit 1
      fi
      ;;
    brew-cask)
      if ! caffeinate -i brew upgrade --cask "$app_id"; then
        printf '[%d/%d] ✗ mislukt: %s. De resterende %d updates zijn overgeslagen.\n' \
          "$current_update" "$total_updates" "$label" "$remaining_updates" >&2
        exit 1
      fi
      ;;
    mas)
      if ! mas upgrade "$app_id"; then
        printf '[%d/%d] ✗ mislukt: %s. De resterende %d updates zijn overgeslagen.\n' \
          "$current_update" "$total_updates" "$label" "$remaining_updates" >&2
        exit 1
      fi
      ;;
  esac
  printf '[%d/%d] ✓ klaar: %s — nog %d updates te gaan\n' \
    "$current_update" "$total_updates" "$label" "$remaining_updates"
done

echo
echo "Updates voltooid. Gebruik Reload configuration als je ook de dotfiles wilt toepassen."
