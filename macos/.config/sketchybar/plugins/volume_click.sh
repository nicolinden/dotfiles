#!/usr/bin/env bash

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh"

WIDTH=100

toggle_detail() {
  local initial_width
  initial_width="$(sketchybar --query volume | jq -r '.slider.width')"
  if [[ "$initial_width" == "0" ]]; then
    sketchybar --animate tanh 30 --set volume slider.width=$WIDTH
  else
    sketchybar --animate tanh 30 --set volume slider.width=0
  fi
}

toggle_devices() {
  local counter=0 current device color
  local args

  command -v SwitchAudioSource >/dev/null 2>&1 || return 0
  args=(--remove '/volume.device\.*/' --set "$NAME" popup.drawing=toggle)
  current="$(SwitchAudioSource -t output -c)"

  while IFS= read -r device; do
    color="$GREY"
    [[ "$device" == "$current" ]] && color="$WHITE"
    args+=(--add item "volume.device.$counter" "popup.$NAME"
           --set "volume.device.$counter"
             "label=$device"
             "label.color=$color"
             "click_script=SwitchAudioSource -s \"$device\" && sketchybar --set $NAME popup.drawing=off")
    counter=$((counter + 1))
  done <<< "$(SwitchAudioSource -a -t output)"

  sketchybar "${args[@]}"
}

if [[ "${BUTTON:-left}" == "right" || "${MODIFIER:-}" == "shift" ]]; then
  toggle_devices
else
  toggle_detail
fi
