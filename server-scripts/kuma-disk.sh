#!/usr/bin/env bash
set -euo pipefail

# Configureer de geheime push-URL lokaal op de server, buiten Git.
config_file="${KUMA_DISK_CONFIG:-/etc/dotfiles/kuma-disk.env}"
if [[ -r "$config_file" ]]; then
  # shellcheck disable=SC1090
  source "$config_file"
fi
: "${KUMA_DISK_PUSH_URL:?Set KUMA_DISK_PUSH_URL in $config_file}"

mount="${KUMA_DISK_MOUNT:-/mnt/mediadisk}"
threshold="${KUMA_DISK_THRESHOLD:-90}"
used_pct="$(df -P "$mount" | awk 'NR==2 {gsub("%","",$5); print $5}')"
[[ "$used_pct" =~ ^[0-9]+$ ]] || { echo "Kon schijfgebruik niet bepalen." >&2; exit 1; }
status=up
message="Disk $mount OK: ${used_pct}% used (threshold ${threshold}%)"
if (( used_pct >= threshold )); then
  status=down
  message="Disk $mount HIGH: ${used_pct}% used (threshold ${threshold}%)"
fi
curl -fsS -m 10 -G "$KUMA_DISK_PUSH_URL" \
  --data-urlencode "status=$status" --data-urlencode "msg=$message" \
  --data-urlencode "ping=$used_pct" >/dev/null
echo "$(date -Is) sent status=$status used=${used_pct}% mount=$mount"
