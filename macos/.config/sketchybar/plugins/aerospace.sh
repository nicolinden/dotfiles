#!/usr/bin/env bash

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"

source "$CONFIG_DIR/plugins/icon_map.sh"

WORKSPACE="$1"
ACTIVE_WORKSPACE="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"
ICONS=""

while IFS= read -r APP; do
  ICON="$(icon_for_app "$APP")"

  # Show each application icon only once per workspace
  if [[ " $ICONS " != *" $ICON "* ]]; then
    if [[ -n "$ICONS" ]]; then
      ICONS="$ICONS $ICON"
    else
      ICONS="$ICON"
    fi
  fi
done < <(
  aerospace list-windows \
    --workspace "$WORKSPACE" \
    --format '%{app-name}'
)

if [[ "$WORKSPACE" == "$ACTIVE_WORKSPACE" ]]; then
  sketchybar --set "$NAME" \
    label="$ICONS" \
    icon.color=0xff011423 \
    label.color=0xff011423 \
    background.drawing=on
else
  sketchybar --set "$NAME" \
    label="$ICONS" \
    icon.color=0xffcbe0f0 \
    label.color=0xffcbe0f0 \
    background.drawing=off
fi
