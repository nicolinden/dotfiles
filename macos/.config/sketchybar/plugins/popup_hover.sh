#!/usr/bin/env bash

# Reliable popup dismissal fallback for macOS versions where
# mouse.exited.global is occasionally missed by SketchyBar.
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/Library/Caches}/sketchybar"

popup_hover_enter() {
  local popup="$1"
  mkdir -p "$CACHE_DIR"
  printf '%s\n' "${RANDOM}.$$" >"$CACHE_DIR/popup-${popup}.hover"
}

popup_hover_exit() {
  local popup="$1" marker token
  marker="$CACHE_DIR/popup-${popup}.hover"
  token="$(command cat "$marker" 2>/dev/null || true)"
  if [[ -z "$token" ]]; then
    mkdir -p "$CACHE_DIR"
    token="${RANDOM}.$$"
    printf '%s\n' "$token" >"$marker"
  fi
  (
    sleep 0.35
    [[ -n "$token" && "$(command cat "$marker" 2>/dev/null || true)" != "$token" ]] && exit 0
    sketchybar --set "$popup" popup.drawing=off
  ) &
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  case "${SENDER:-}" in
    mouse.entered) popup_hover_enter "${1:?popup name required}" ;;
    mouse.exited) popup_hover_exit "${1:?popup name required}" ;;
  esac
fi
