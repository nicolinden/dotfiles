#!/usr/bin/env bash

set -uo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SERVICE="sap-hana-start.service"
readonly TIMER="sap-hana-start.timer"
problem_found=false

ok() { printf 'OK: %s\n' "$1"; }
fail() { printf 'FOUT: %s\n' "$1"; problem_found=true; }
info() { printf 'INFO: %s\n' "$1"; }
run_cf() { docker compose --project-directory "$SCRIPT_DIR" --file "$SCRIPT_DIR/compose.yaml" run --rm -T cf "$@"; }

printf '%s SAP HANA/PlayNext-controle\n\n' "$(date --iso-8601=seconds)"
systemctl is-enabled --quiet "$TIMER" && ok "de dagelijkse timer is ingeschakeld." || fail "de dagelijkse timer is niet ingeschakeld."
systemctl is-active --quiet "$TIMER" && ok "de dagelijkse timer is actief." || fail "de dagelijkse timer is niet actief."
result="$(systemctl show "$SERVICE" --property=Result --value)"
[[ "$result" == success ]] && ok "de laatste uitvoering was succesvol." || fail "de laatste uitvoering was niet succesvol (${result:-onbekend})."

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
[[ "$problem_found" == false ]] || exit 1
printf '\nRESULTAAT: alles is in orde.\n'
