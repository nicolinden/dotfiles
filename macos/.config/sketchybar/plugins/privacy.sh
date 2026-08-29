#!/usr/bin/env bash

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh"

SOURCE="$CONFIG_DIR/helpers/media_usage.c"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/Library/Caches}/sketchybar"
HELPER="$CACHE_DIR/media-usage"

mkdir -p "$CACHE_DIR"
if [[ ! -x "$HELPER" || "$SOURCE" -nt "$HELPER" ]]; then
  TEMP_HELPER="$(mktemp "$CACHE_DIR/media-usage.XXXXXX")" || exit 0
  if /usr/bin/clang -x objective-c -O2 -Wall -Wextra \
      -framework CoreAudio -framework CoreMediaIO \
      "$SOURCE" -o "$TEMP_HELPER" 2>/dev/null; then
    chmod 700 "$TEMP_HELPER"
    mv "$TEMP_HELPER" "$HELPER"
  else
    rm -f "$TEMP_HELPER"
    exit 0
  fi
fi

STATUS="$($HELPER 2>/dev/null)" || exit 0
MIC="${STATUS#*mic=}"
MIC="${MIC%% *}"
CAMERA="${STATUS#*camera=}"
CAMERA="${CAMERA%% *}"

if [[ "$MIC" == 1 ]]; then
  sketchybar --set privacy.mic drawing=on icon.color="$ORANGE"
else
  sketchybar --set privacy.mic drawing=off
fi

if [[ "$CAMERA" == 1 ]]; then
  sketchybar --set privacy.camera drawing=on icon.color="$GREEN"
else
  sketchybar --set privacy.camera drawing=off
fi
