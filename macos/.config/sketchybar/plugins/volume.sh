#!/usr/bin/env bash

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/icons.sh"

WIDTH=100

set_volume_icon() {
  local volume="$1" icon="$VOLUME_100"

  case "$volume" in
    [6-9][0-9]|100) icon="$VOLUME_100" ;;
    [3-5][0-9]) icon="$VOLUME_66" ;;
    [1-2][0-9]) icon="$VOLUME_33" ;;
    [1-9]) icon="$VOLUME_10" ;;
    0) icon="$VOLUME_0" ;;
  esac

  sketchybar --set volume_icon label="$icon"
}

volume_change() {
  local volume="${INFO:-$(osascript -e 'output volume of (get volume settings)')}"
  local final_percentage

  set_volume_icon "$volume"
  sketchybar --set "$NAME" slider.percentage="$volume" \
             --animate tanh 30 --set "$NAME" slider.width=$WIDTH

  sleep 2
  final_percentage="$(sketchybar --query "$NAME" | jq -r '.slider.percentage')"
  if [[ "$final_percentage" == "$volume" ]]; then
    sketchybar --animate tanh 30 --set "$NAME" slider.width=0
  fi
}

case "${SENDER:-forced}" in
  volume_change|forced) volume_change ;;
  mouse.clicked) osascript -e "set volume output volume $PERCENTAGE" ;;
  mouse.entered) sketchybar --set "$NAME" slider.knob.drawing=on ;;
  mouse.exited) sketchybar --set "$NAME" slider.knob.drawing=off ;;
esac
