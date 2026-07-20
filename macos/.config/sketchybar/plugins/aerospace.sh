#!/usr/bin/env bash

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"

source "$CONFIG_DIR/plugins/icon_map.sh"

WORKSPACE="$1"
DISPLAY="$2"

# SketchyBar gebruikt dezelfde AppKit-schermvolgorde als AeroSpace. Vertaal
# daarom de scherm-ID naar AeroSpace's monitor-ID en vraag de zichtbare
# workspace op voor dat specifieke scherm op.
MONITOR_ID="$(aerospace list-monitors \
  --format '%{monitor-appkit-nsscreen-screens-id} %{monitor-id}' \
  | awk -v display="$DISPLAY" '$1 == display { print $2; exit }')"

ACTIVE_WORKSPACE=""
if [[ -n "$MONITOR_ID" ]]; then
  ACTIVE_WORKSPACE="$(aerospace list-workspaces --monitor "$MONITOR_ID" --visible)"
fi

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
