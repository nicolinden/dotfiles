#!/usr/bin/env bash

BATTERY_INFO="$(pmset -g batt)"
PERCENTAGE="$(echo "$BATTERY_INFO" | grep -Eo '[0-9]+%' | head -n 1)"

if [[ -z "$PERCENTAGE" ]]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

if echo "$BATTERY_INFO" | grep -q "AC Power"; then
  ICON="󰂄"
else
  ICON="󰁹"
fi

sketchybar --set "$NAME" \
  drawing=on \
  icon="$ICON" \
  label="$PERCENTAGE"
