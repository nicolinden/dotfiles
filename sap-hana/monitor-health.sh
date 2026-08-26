#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly STATE_DIR="${SAP_STATE_DIR:-${SCRIPT_DIR}/state}"
if [[ -r "${SCRIPT_DIR}/notification.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/notification.env"
  set +a
fi
readonly FRONTEND_URL="${SAP_FRONTEND_URL:-https://216fb3e1trial-dev-playnext.cfapps.us10-001.hana.ondemand.com}"
readonly BACKEND_URL="${SAP_BACKEND_URL:-https://216fb3e1trial-dev-playnext-srv.cfapps.us10-001.hana.ondemand.com}"

mkdir -p "$STATE_DIR"
now="$(date +%s)"

reachable() {
  local url="$1" body_file code
  body_file="$(mktemp)"
  code="$(curl --silent --show-error --location --output "$body_file" --connect-timeout 8 --max-time 20 --write-out '%{http_code}' "$url" 2>/dev/null || true)"
  if [[ "$code" =~ ^[234][0-9][0-9]$ ]] &&
     ! { [[ "$code" == 404 ]] && grep -Fqi 'Requested route' "$body_file"; }; then
    rm -f "$body_file"
    return 0
  fi
  rm -f "$body_file"
  return 1
}

frontend=down
backend=down
reachable "$FRONTEND_URL" && frontend=up
reachable "$BACKEND_URL" && backend=up

if [[ "$frontend" == up && "$backend" == up ]]; then
  previous="$(<"$STATE_DIR/last-status" 2>/dev/null || true)"
  printf 'up\n' >"$STATE_DIR/last-status"
  if [[ "$previous" == down ]]; then
    "$SCRIPT_DIR/notify-ha.sh" "SAP HANA/PlayNext is weer bereikbaar." info 0
  fi
fi

last_online="$(<"$STATE_DIR/last-online.epoch" 2>/dev/null || true)"
if [[ "$last_online" =~ ^[0-9]+$ ]] && (( now >= last_online )); then
  offline_days=$(( (now - last_online) / 86400 ))
else
  offline_days=-1
fi

last_alert_day="$(<"$STATE_DIR/last-alert-day" 2>/dev/null || true)"

if [[ "$frontend" == down || "$backend" == down ]]; then
  previous="$(<"$STATE_DIR/last-status" 2>/dev/null || true)"
  printf 'down\n' >"$STATE_DIR/last-status"
  message="SAP-omgeving niet volledig bereikbaar: frontend=${frontend}, backend=${backend}."
  [[ "$previous" == down ]] || "$SCRIPT_DIR/notify-ha.sh" "$message" warning "$offline_days"
  echo "WAARSCHUWING: $message"
else
  echo "OK: frontend en backend zijn bereikbaar."
fi

if (( offline_days >= 21 )) && [[ "$last_alert_day" != "$offline_days" ]]; then
  "$SCRIPT_DIR/notify-ha.sh" "SAP Trial: de laatste volledig geslaagde start via het script was ${offline_days} dagen geleden. Start de omgeving vóór dag 30." warning "$offline_days"
  printf '%s\n' "$offline_days" >"$STATE_DIR/last-alert-day"
fi

if [[ "$frontend" == down || "$backend" == down ]]; then exit 1; fi
