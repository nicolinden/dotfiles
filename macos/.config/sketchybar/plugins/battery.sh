#!/usr/bin/env bash

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

BATTERY_INFO="$(pmset -g batt)"
PERCENTAGE="$(echo "$BATTERY_INFO" | grep -Eo '[0-9]+%' | head -n 1)"

if [[ -z "$PERCENTAGE" ]]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

PERCENTAGE_NUMBER="${PERCENTAGE%%%}"

if echo "$BATTERY_INFO" | grep -q "AC Power"; then
  ICON="$BATTERY_CHARGING"
  COLOR="$GREEN"
elif [[ "$PERCENTAGE_NUMBER" -lt 20 ]]; then
  ICON="$BATTERY_0"
  COLOR="$RED"
elif [[ "$PERCENTAGE_NUMBER" -lt 50 ]]; then
  ICON="$BATTERY_25"
  COLOR="$ORANGE"
elif [[ "$PERCENTAGE_NUMBER" -lt 80 ]]; then
  ICON="$BATTERY_50"
  COLOR="$WHITE"
elif [[ "$PERCENTAGE_NUMBER" -lt 90 ]]; then
  ICON="$BATTERY_75"
  COLOR="$WHITE"
else
  ICON="$BATTERY_100"
  COLOR="$WHITE"
fi

sketchybar --set "$NAME" \
  drawing=on \
  icon="$ICON" \
  icon.color="$COLOR" \
  label=""
