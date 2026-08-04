#!/usr/bin/env bash

case "${1:-close}" in
  toggle)
    sketchybar --set apple popup.drawing=toggle
    ;;
  close)
    sketchybar --set apple popup.drawing=off
    ;;
  preferences)
    sketchybar --set apple popup.drawing=off
    open "x-apple.systempreferences:"
    ;;
  activity)
    sketchybar --set apple popup.drawing=off
    open -a "Activity Monitor"
    ;;
  lock)
    sketchybar --set apple popup.drawing=off
    osascript -e 'tell application "System Events" to keystroke "q" using {control down, command down}'
    ;;
esac
