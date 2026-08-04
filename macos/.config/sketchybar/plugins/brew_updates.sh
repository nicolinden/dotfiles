#!/usr/bin/env bash

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh"

if ! command -v brew >/dev/null 2>&1; then
  sketchybar --set "$NAME" label="–"
  exit 0
fi

COUNT="$(brew outdated --quiet 2>/dev/null | awk 'END { print NR + 0 }')"
COLOR="$RED"

case "$COUNT" in
  0) COLOR="$GREEN" ;;
  [1-9]) COLOR="$WHITE" ;;
  [1-2][0-9]) COLOR="$YELLOW" ;;
  [3-5][0-9]) COLOR="$ORANGE" ;;
esac

sketchybar --set "$NAME" label="$COUNT" icon.color="$COLOR"
