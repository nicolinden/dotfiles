#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly ENV_FILE="${SCRIPT_DIR}/notification.env"

[[ -r "$ENV_FILE" ]] || { echo "notification.env ontbreekt of is niet leesbaar." >&2; exit 1; }
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a
: "${SAP_FAILURE_WEBHOOK_URL:?SAP_FAILURE_WEBHOOK_URL ontbreekt in notification.env}"

message="${1:-SAP HANA/PlayNext vereist aandacht.}"
severity="${2:-warning}"
offline_days="${3:-}"

json="$(printf '%s\n%s\n%s\n' "$message" "$severity" "$offline_days" | python3 -c 'import json,sys; a=sys.stdin.read().splitlines(); print(json.dumps({"message":a[0],"severity":a[1],"offline_days":int(a[2]) if len(a)>2 and a[2].isdigit() else None}))')"
/usr/bin/curl --fail --silent --show-error --output /dev/null \
  --retry 2 --retry-all-errors --connect-timeout 5 --max-time 10 \
  --header 'Content-Type: application/json' --request POST --data "$json" \
  "$SAP_FAILURE_WEBHOOK_URL"
