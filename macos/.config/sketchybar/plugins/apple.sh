#!/usr/bin/env bash

ACTION="${1:-update}"
ITEM="${2:-${NAME:-apple.1}}"

update_system_info() {
  local item="$1" user_name boot_epoch now elapsed days hours minutes uptime_text

  user_name="$(id -F 2>/dev/null || id -un)"
  boot_epoch="$(sysctl -n kern.boottime 2>/dev/null | awk -F '[=,]' '{ gsub(/[^0-9]/, "", $2); print $2 }')"
  now="$(date +%s)"

  if [[ "$boot_epoch" =~ ^[0-9]+$ ]] && (( now >= boot_epoch )); then
    elapsed=$((now - boot_epoch))
    days=$((elapsed / 86400))
    hours=$(((elapsed % 86400) / 3600))
    minutes=$(((elapsed % 3600) / 60))
    if (( days > 0 )); then
      uptime_text="${days}d ${hours}u ${minutes}m"
    elif (( hours > 0 )); then
      uptime_text="${hours}u ${minutes}m"
    else
      uptime_text="${minutes}m"
    fi
  else
    uptime_text="onbekend"
  fi

  sketchybar --set "$item.user" "label=$user_name" \
             --set "$item.uptime" "label=Uptime · $uptime_text"
}

case "$ACTION" in
  toggle)
    update_system_info "$ITEM"
    sketchybar --set "$ITEM" popup.drawing=toggle
    ;;
  update)
    source "${CONFIG_DIR:-$HOME/.config/sketchybar}/colors.sh"
    DISPLAY="${3:-1}"
    update_system_info "$ITEM"

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
