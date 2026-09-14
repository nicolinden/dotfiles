#!/usr/bin/env bash

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh"

ITEM="${NAME:-caffeinated}"

caffeinated_state() {
  local pid

  pid="$(pgrep -x Caffeinated 2>/dev/null | head -n 1)"
  if [[ -z "$pid" ]]; then
    printf 'stopped'
    return
  fi

  if pmset -g assertions 2>/dev/null \
    | grep -F "pid $pid(Caffeinated):" \
    | grep -q 'Sleep mode disabled by user'; then
    printf 'active'
  else
    printf 'inactive'
  fi
}

update_item() {
  case "$(caffeinated_state)" in
    active)
      sketchybar --set "$ITEM" drawing=on icon.color="$GREEN"
      ;;
    inactive)
      sketchybar --set "$ITEM" drawing=on icon.color="$GREY"
      ;;
    stopped)
      sketchybar --set "$ITEM" drawing=off
      ;;
  esac
}

if [[ "${1:-}" == "toggle" ]]; then
  previous_state="$(caffeinated_state)"
  [[ "$previous_state" != "stopped" ]] || exit 0
  if [[ "$previous_state" == "active" ]]; then
    command_to_run=deactivate
  else
    command_to_run=activate
  fi

  # The app's generic `toggle` AppleScript command is occasionally ignored.
  # Explicit activate/deactivate commands are deterministic; retry once if its
  # asynchronous power assertion has not changed yet.
  for _attempt in 1 2; do
    osascript -e "tell application \"Caffeinated\" to $command_to_run" >/dev/null
    for _ in {1..30}; do
      [[ "$(caffeinated_state)" != "$previous_state" ]] && break 2
      sleep 0.1
    done
  done
fi

update_item
