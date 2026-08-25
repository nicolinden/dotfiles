#!/usr/bin/env bash

set -uo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SERVICE="sap-hana-start.service"
readonly TIMER="sap-hana-start.timer"
problem_found=false

ok() { printf 'OK: %s\n' "$1"; }
fail() { printf 'FOUT: %s\n' "$1"; problem_found=true; }
run_cf() { docker compose --project-directory "$SCRIPT_DIR" --file "$SCRIPT_DIR/compose.yaml" run --rm -T cf "$@"; }

printf '%s SAP HANA/PlayNext-controle\n\n' "$(date --iso-8601=seconds)"
systemctl is-enabled --quiet "$TIMER" && ok "de dagelijkse timer is ingeschakeld." || fail "de dagelijkse timer is niet ingeschakeld."
systemctl is-active --quiet "$TIMER" && ok "de dagelijkse timer is actief." || fail "de dagelijkse timer is niet actief."
result="$(systemctl show "$SERVICE" --property=Result --value)"
[[ "$result" == success ]] && ok "de laatste uitvoering was succesvol." || fail "de laatste uitvoering was niet succesvol (${result:-onbekend})."

if run_cf service ExamDB >/dev/null 2>&1; then
  ok "Cloud Foundry is bereikbaar en ExamDB bestaat."
else
  fail "Cloud Foundry-login of toegang tot ExamDB werkt niet."
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

printf '\nVolgende geplande uitvoering:\n'
systemctl list-timers "$TIMER" --no-pager
[[ "$problem_found" == false ]] || exit 1
printf '\nRESULTAAT: alles is in orde.\n'
