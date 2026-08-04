#!/usr/bin/env bash

# Exact Macchiato palette used by FelixKratz in the referenced configuration.
BLACK=0xff181926
WHITE=0xffcad3f5
RED=0xffed8796
GREEN=0xffa6da95
BLUE=0xff8aadf4
YELLOW=0xffeed49f
ORANGE=0xfff5a97f
MAGENTA=0xffc6a0f6
GREY=0xff939ab7
TRANSPARENT=0x00000000

# Keep the native macOS menu bar behind SketchyBar without letting its text
# bleed through. The grouped items retain the translucent reference styling.
BAR_COLOR=0xff24273a
BACKGROUND_1=0x903c3e4f
BACKGROUND_2=0x90494d64
POPUP_BACKGROUND_COLOR=0xff24273a
POPUP_BORDER_COLOR=$WHITE
SHADOW_COLOR=$BLACK

# Names used by the existing event-driven workspace implementation.
PANEL_COLOR=$BACKGROUND_1
PANEL_HIGHLIGHT=$BACKGROUND_2
BORDER_COLOR=$BACKGROUND_2
FOREGROUND=$WHITE
MUTED=$GREY
ACCENT=$BLUE
ACCENT_MUTED=$BACKGROUND_2
ACTIVE_WORKSPACE=$RED
APP_ACCENT=$ORANGE
APPLE_GREEN=$GREEN
