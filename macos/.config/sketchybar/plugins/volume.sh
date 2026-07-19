#!/usr/bin/env bash

VOLUME="${INFO:-$(osascript -e 'output volume of (get volume settings)')}"
MUTED="$(osascript -e 'output muted of (get volume settings)')"

if [[ "$MUTED" == "true" || "$VOLUME" -eq 0 ]]; then
  ICON="󰕿"
  LABEL=""
elif [[ "$VOLUME" -lt 34 ]]; then
  ICON="󰕿"
  LABEL="${VOLUME}%"
elif [[ "$VOLUME" -lt 67 ]]; then
  ICON="󰖀"
  LABEL="${VOLUME}%"
else
  ICON="󰕾"
  LABEL="${VOLUME}%"
fi

sketchybar --set "$NAME" \
  icon="$ICON" \
  label="$LABEL"
