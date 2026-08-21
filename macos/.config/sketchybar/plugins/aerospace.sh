#!/usr/bin/env bash

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"

source "$CONFIG_DIR/plugins/icon_map.sh"
source "$CONFIG_DIR/colors.sh"

# Eén snapshot per event. Daardoor blijven focus- en workspacewisselingen ook
# met meerdere schermen vloeiend: geen process-spawn per indicator.
MONITORS="$(aerospace list-monitors \
  --format '%{monitor-appkit-nsscreen-screens-id}|%{monitor-is-main}' 2>/dev/null)" || exit 0
WORKSPACES="$(aerospace list-workspaces --all \
  --format '%{workspace}|%{monitor-appkit-nsscreen-screens-id}|%{workspace-is-visible}|%{workspace-is-focused}' 2>/dev/null)" || exit 0
WINDOWS="$(aerospace list-windows --all \
  --format '%{workspace}|%{app-name}' 2>/dev/null)" || exit 0

display_prefix() {
  local display="$1"
  local current_display is_main

  while IFS='|' read -r current_display is_main; do
    if [[ "$current_display" == "$display" ]]; then
      if [[ "$is_main" == "true" ]]; then
        printf 'main'
      else
        printf 'side'
      fi
      return
    fi
  done <<< "$MONITORS"
}

workspace_state() {
  local target_workspace="$1"
  local workspace _display visible focused

  while IFS='|' read -r workspace _display visible focused; do
    if [[ "$workspace" == "$target_workspace" ]]; then
      printf '%s|%s' "$visible" "$focused"
      return
    fi
  done <<< "$WORKSPACES"

  printf 'false|false'
}

workspace_icons() {
  local target_workspace="$1"
  local workspace app icon icons=""

  while IFS='|' read -r workspace app; do
    [[ "$workspace" == "$target_workspace" ]] || continue

    icon="$(icon_for_app "$app")"
    if [[ " $icons " != *" $icon "* ]]; then
      icons="${icons:+$icons }$icon"
    fi
  done <<< "$WINDOWS"

  printf '%s' "$icons"
}

workspace_has_windows() {
  local target_workspace="$1"
  local workspace _app

  while IFS='|' read -r workspace _app; do
    if [[ "$workspace" == "$target_workspace" ]]; then
      return 0
    fi
  done <<< "$WINDOWS"

  return 1
}

SKETCHYBAR_ARGS=()

for display in 1 2 3; do
  prefix="$(display_prefix "$display")"

  for slot in {1..10}; do
    item="workspace.$display.$slot"

    # Niet-aangesloten schermen krijgen geen indicatoren; dat voorkomt
    # achtergebleven items na het loskoppelen van een monitor.
    if [[ -z "$prefix" ]]; then
      SKETCHYBAR_ARGS+=(--set "$item" drawing=off)
      continue
    fi

    fixed=false
    if [[ "$prefix" == "main" ]]; then
      case "$slot" in
        1) workspace="V"; fixed=true ;;
        2) workspace="B"; fixed=true ;;
        3) workspace="F"; fixed=true ;;
        4) workspace="T"; fixed=true ;;
        *) workspace="main-$((slot - 4))" ;;
      esac
    else
      workspace="side-$slot"
    fi

    state="$(workspace_state "$workspace")"
    visible="${state%%|*}"
    focused="${state##*|}"
    icons="$(workspace_icons "$workspace")"

    # V, B, F en T staan altijd op het hoofdscherm. Numerieke workspaces
    # verschijnen alleen wanneer ze een venster bevatten of actief zijn.
    if [[ "$fixed" != "true" ]] \
      && ! workspace_has_windows "$workspace" \
      && [[ "$visible" != "true" ]]; then
      SKETCHYBAR_ARGS+=(--set "$item" drawing=off)
      continue
    fi

    if [[ "$visible" == "true" ]]; then
      if [[ "$focused" == "true" ]]; then
        icon_color="$ACTIVE_WORKSPACE"
      else
        # De zichtbare, maar niet-gefocuste workspace blijft nadrukkelijk
        # herkenbaar, ook als er geen app-iconen in staan.
        icon_color="$FOREGROUND"
      fi

      SKETCHYBAR_ARGS+=(
        --set "$item"
        drawing=on
        "label=$icons"
        "icon.color=$icon_color"
        "label.color=$FOREGROUND"
        background.border_width=0
        background.drawing=off
      )
    else
      SKETCHYBAR_ARGS+=(
        --set "$item"
        drawing=on
        "label=$icons"
        "icon.color=$FOREGROUND"
        "label.color=$FOREGROUND"
        "background.color=$PANEL_COLOR"
        "background.border_color=$BORDER_COLOR"
        background.border_width=0
        background.drawing=off
      )
    fi
  done
done

if (( ${#SKETCHYBAR_ARGS[@]} > 0 )); then
  sketchybar "${SKETCHYBAR_ARGS[@]}"
fi
