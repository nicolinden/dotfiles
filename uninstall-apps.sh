#!/usr/bin/env bash

# Remove individually selected optional macOS apps. Core tooling is excluded.
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
  local kind name install_kind

  while IFS='|' read -r kind name; do
    [[ -n "$name" ]] || continue
    if [[ "$kind" == "brew" ]] && brew list --formula "$name" >/dev/null 2>&1; then
      install_kind="formula"
      entries+=("$install_kind|$name|$name|$file|$kind")
    elif [[ "$kind" == "cask" ]] && brew list --cask "$name" >/dev/null 2>&1; then
      install_kind="cask"
      entries+=("$install_kind|$name|$name|$file|$kind")
    fi
  done < <(sed -nE 's/^(brew|cask) "([^"]+)".*/\1|\2/p' "$file")
}

add_brewfile_entries "$DOTFILES_DIR/Brewfile.dev"
add_brewfile_entries "$DOTFILES_DIR/Brewfile.personal"
add_brewfile_entries "$DOTFILES_DIR/Brewfile.office"

if brew list --cask docker-desktop >/dev/null 2>&1; then
  entries+=("cask|docker-desktop|Docker Desktop|$DOTFILES_DIR/system-apps.conf|system-cask")
fi

if command -v mas >/dev/null 2>&1; then
  mas_list="$(mas list 2>/dev/null || true)"
  for file in "$DOTFILES_DIR/Brewfile.mas" "$DOTFILES_DIR/Brewfile.office.mas"; do
    while IFS='|' read -r id name; do
      [[ -n "$id" ]] || continue
      if printf '%s\n' "$mas_list" | grep -q "^$id "; then
        entries+=("mas|$id|$name|$file|mas")
      fi
    done < <(sed -nE 's/^mas "([^"]+)", id: ([0-9]+).*/\2|\1/p' "$file")
  done
fi

if (( ${#entries[@]} == 0 )); then
  echo "No optional apps from this repository are installed."
  exit 0
fi

print_menu_header "Remove optional macOS apps"
for index in "${!entries[@]}"; do
  IFS='|' read -r kind _id label _file _config_kind <<< "${entries[$index]}"
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

echo
read -r -p "Ook uit de dotfiles-config verwijderen? [y/N] " config_confirmation
case "$config_confirmation" in
  y|Y|yes|YES|Yes) remove_from_config=true ;;
  *) remove_from_config=false ;;
esac

remove_regular_config_entry() {
  local file="$1"
  local config_kind="$2"
  local id="$3"
  local temp_file

  temp_file="$(mktemp "${file}.XXXXXX")"
  awk -v kind="$config_kind" -v id="$id" '
    kind == "mas" {
      if ($0 ~ /^mas / && $0 ~ ("id: " id "([, ]|$)")) next
      print
      next
    }
    index($0, kind " \"" id "\"") == 1 { next }
    { print }
  ' "$file" > "$temp_file"
  chmod "$(stat -f '%Lp' "$file")" "$temp_file"
  mv "$temp_file" "$file"
}

remove_system_cask_config() {
  local file="$1"
  local id="$2"
  local temp_file

  temp_file="$(mktemp "${file}.XXXXXX")"
  awk -v id="$id" '
    /^SYSTEM_CASKS=\(/ { section = "casks"; print; next }
    /^SYSTEM_LABELS=\(/ { section = "labels"; print; next }
    section == "casks" && /^\)/ { section = ""; print; next }
    section == "labels" && /^\)/ { section = ""; print; next }
    section == "casks" && /^[[:space:]]*"/ {
      cask_index++
      if ($0 ~ ("\"" id "\"")) {
        removed_index = cask_index
        next
      }
    }
    section == "labels" && /^[[:space:]]*"/ {
      label_index++
      if (label_index == removed_index) next
    }
    { print }
  ' "$file" > "$temp_file"
  chmod "$(stat -f '%Lp' "$file")" "$temp_file"
  mv "$temp_file" "$file"
}

for choice in "${selected[@]}"; do
  IFS='|' read -r kind id label config_file config_kind <<< "${entries[$((choice - 1))]}"
  echo "Removing: $label"
  case "$kind" in
    formula) brew uninstall "$id" ;;
    cask) brew uninstall --cask "$id" ;;
    mas) mas uninstall "$id" ;;
  esac

  if [[ "$remove_from_config" == true ]]; then
    if [[ "$config_kind" == "system-cask" ]]; then
      remove_system_cask_config "$config_file" "$id"
    else
      remove_regular_config_entry "$config_file" "$config_kind" "$id"
    fi
    echo "Uit configuratie verwijderd: $label"
  fi
done

refresh_sketchybar_updates
echo "Selected apps have been removed."
