#!/usr/bin/env bash

ACTION="${1:-update}"
ITEM="${2:-${NAME:-apple.1}}"

case "$ACTION" in
  toggle)
    sketchybar --set "$ITEM" popup.drawing=toggle
    ;;
  update)
    source "${CONFIG_DIR:-$HOME/.config/sketchybar}/colors.sh"
    DISPLAY="${3:-1}"

    if [[ "${SENDER:-}" == "mouse.exited.global" ]]; then
      sketchybar --set "$ITEM" popup.drawing=off
      exit 0
    fi

    FOCUSED_DISPLAY="$(aerospace list-monitors --focused \
      --format '%{monitor-appkit-nsscreen-screens-id}' 2>/dev/null || true)"

    if [[ "$FOCUSED_DISPLAY" == "$DISPLAY" ]]; then
      sketchybar --set "$ITEM" icon.color="$APPLE_GREEN"
    else
      sketchybar --set "$ITEM" icon.color="$MUTED" popup.drawing=off
    fi
    ;;
  preferences)
    sketchybar --set "$ITEM" popup.drawing=off
    open "x-apple.systempreferences:"
    ;;
  activity)
    sketchybar --set "$ITEM" popup.drawing=off
    open -a "Activity Monitor"
    ;;
  lock)
    sketchybar --set "$ITEM" popup.drawing=off
    osascript -e 'tell application "System Events" to keystroke "q" using {control down, command down}'
    ;;
esac
