#!/usr/bin/env bash

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"

source "$CONFIG_DIR/plugins/icon_map.sh"

DISPLAY="$1"

FOCUSED_DISPLAY="$(aerospace list-monitors --focused \
  --format '%{monitor-appkit-nsscreen-screens-id}' 2>/dev/null || true)"

if [[ "$FOCUSED_DISPLAY" != "$DISPLAY" ]]; then
  sketchybar --set "$NAME" drawing=off \
             --set "app_separator.$DISPLAY" drawing=off
  exit 0
fi

APP_NAME="${INFO:-}"
if [[ "$SENDER" == "aerospace_focus_change" || -z "$APP_NAME" ]]; then
  APP_NAME="$(aerospace list-windows --focused --format '%{app-name}' 2>/dev/null)"
fi

if [[ -z "$APP_NAME" ]]; then
  sketchybar --set "$NAME" drawing=off \
             --set "app_separator.$DISPLAY" drawing=off
  exit 0
fi

APP_ICON="$(icon_for_app "$APP_NAME")"

sketchybar --set "$NAME" \
  icon="$APP_ICON" \
  label="$APP_NAME" \
  drawing=on \
  --set "app_separator.$DISPLAY" drawing=on
