#!/usr/bin/env bash

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"

source "$CONFIG_DIR/plugins/icon_map.sh"

APP_NAME="$INFO"

if [[ -z "$APP_NAME" ]]; then
  APP_NAME="$(aerospace list-windows --focused --format '%{app-name}' 2>/dev/null)"
fi

APP_ICON="$(icon_for_app "$APP_NAME")"

sketchybar --set "$NAME" \
  icon="$APP_ICON" \
  label="$APP_NAME"
