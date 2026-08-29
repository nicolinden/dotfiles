#!/usr/bin/env bash

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh"

CPU_LINE="$(top -l 1 -n 0 2>/dev/null | awk '/CPU usage/ { gsub(/%/, ""); print $3, $5; exit }')"
USER_LOAD="${CPU_LINE%% *}"
SYS_LOAD="${CPU_LINE##* }"

if [[ -z "$USER_LOAD" || -z "$SYS_LOAD" ]]; then
  sketchybar --set "$NAME" label="–%"
  exit 0
fi

TOTAL="$(awk -v user="$USER_LOAD" -v sys="$SYS_LOAD" 'BEGIN { printf "%.0f", user + sys }')"
USER_GRAPH="$(awk -v value="$USER_LOAD" 'BEGIN { printf "%.4f", value / 100 }')"
SYS_GRAPH="$(awk -v value="$SYS_LOAD" 'BEGIN { printf "%.4f", value / 100 }')"
LABEL=""
COLOR="$YELLOW"
LABEL_WIDTH=0
if (( TOTAL >= 80 )); then
  LABEL="${TOTAL}%"
  COLOR="$RED"
  LABEL_WIDTH=48
elif (( TOTAL >= 50 )); then
  LABEL="${TOTAL}%"
  LABEL_WIDTH=48
fi

sketchybar --push cpu.user "$USER_GRAPH" \
           --push cpu.sys "$SYS_GRAPH" \
           --set "$NAME" label="$LABEL" label.width="$LABEL_WIDTH" label.color="$COLOR"
