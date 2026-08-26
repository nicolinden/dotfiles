#!/usr/bin/env bash

set -uo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SERVICE="sap-hana-start.service"
readonly TIMER="sap-hana-health.timer"
readonly STATE_DIR="${SAP_STATE_DIR:-${SCRIPT_DIR}/state}"
problem_found=false

ok() { printf 'OK: %s\n' "$1"; }
fail() { printf 'FOUT: %s\n' "$1"; problem_found=true; }
info() { printf 'INFO: %s\n' "$1"; }
run_cf() { docker compose --project-directory "$SCRIPT_DIR" --file "$SCRIPT_DIR/compose.yaml" run --rm -T cf "$@"; }

printf '%s SAP HANA/PlayNext-controle\n\n' "$(date --iso-8601=seconds)"
systemctl is-enabled --quiet "$TIMER" && ok "de achtergrondcontrole is ingeschakeld." || fail "de achtergrondcontrole is niet ingeschakeld."
systemctl is-active --quiet "$TIMER" && ok "de achtergrondcontrole is actief." || fail "de achtergrondcontrole is niet actief."

params="$(run_cf service ExamDB --params 2>/dev/null || true)"
if grep -Eqi '"serviceStopped"[[:space:]]*:[[:space:]]*false' <<<"$params"; then
  ok "ExamDB is aangezet (serviceStopped=false)."
elif grep -Eqi '"serviceStopped"[[:space:]]*:[[:space:]]*true' <<<"$params"; then
  fail "ExamDB staat uit (serviceStopped=true)."
else
  fail "status van ExamDB is onbekend; controleer de Cloud Foundry-login."
fi

for app in playnext-srv playnext; do
  output="$(run_cf app "$app" 2>&1 || true)"
  if grep -Eqi 'requested state:[[:space:]]+started' <<<"$output" &&
     grep -Eqi 'instances:[[:space:]]+1/1' <<<"$output"; then
    ok "$app draait met 1/1 instance."
  else
    fail "$app draait niet gezond met 1/1 instance."
  fi
done

[[ -s "$SCRIPT_DIR/notification.env" ]] && ok "de Home Assistant-webhook is geconfigureerd." || fail "notification.env ontbreekt of is leeg."
if systemctl is-active --quiet "$SERVICE"; then
  info "de starttaak is momenteel bezig."
else
  info "de starttaak is momenteel niet bezig."
fi

printf '\nVolgende geplande uitvoering:\n'
systemctl list-timers "$TIMER" --no-pager
if [[ -s "$STATE_DIR/last-online.epoch" ]]; then
  last_online="$(<"$STATE_DIR/last-online.epoch")"
  if [[ "$last_online" =~ ^[0-9]+$ ]]; then
    offline_days=$(( ($(date +%s) - last_online) / 86400 ))
    info "laatste volledig geslaagde scriptstart: $(date -d "@$last_online" --iso-8601=seconds) (${offline_days} volledige dag(en) geleden)."
  fi
else
  info "er is nog geen bewezen online-moment opgeslagen."
fi
[[ "$problem_found" == false ]] || exit 1
printf '\nRESULTAAT: alles is in orde.\n'
