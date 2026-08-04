#!/usr/bin/env bash

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
TOP_PROCESS="$(ps -arcwwwxo pid=,%cpu=,comm= 2>/dev/null | awk 'NR == 1 { printf "%s  %.1f  %s", $1, $2, $3 }')"

sketchybar --push cpu.user "$USER_GRAPH" \
           --push cpu.sys "$SYS_GRAPH" \
           --set cpu.top label="${TOP_PROCESS:-CPU}" \
           --set "$NAME" label="${TOTAL}%"
