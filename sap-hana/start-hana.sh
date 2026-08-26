#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly COMPOSE_FILE="${SCRIPT_DIR}/compose.yaml"
readonly HANA_INSTANCE="ExamDB"
readonly CF_ORG="216fb3e1trial"
readonly CF_SPACE="dev"
readonly HANA_MAX_CHECKS=30
readonly HANA_CHECK_INTERVAL=20
readonly APP_MAX_CHECKS=30
readonly APP_CHECK_INTERVAL=10
readonly STATE_DIR="${SAP_STATE_DIR:-${SCRIPT_DIR}/state}"

log() { printf '%s %s\n' "$(date --iso-8601=seconds)" "$*"; }

run_cf() {
  docker compose --project-directory "${SCRIPT_DIR}" \
    --file "${COMPOSE_FILE}" run --rm -T cf "$@"
}

normalize_output() { tr '\n' ' ' | tr -s '[:space:]' ' '; }

hana_requested_state() {
  local params
  params="$(run_cf service "${HANA_INSTANCE}" --params 2>/dev/null || true)"
  if grep -Eqi '"serviceStopped"[[:space:]]*:[[:space:]]*false' <<<"$params"; then
    printf 'running'
  elif grep -Eqi '"serviceStopped"[[:space:]]*:[[:space:]]*true' <<<"$params"; then
    printf 'stopped'
  else
    printf 'unknown'
  fi
}

start_hana() {
  local attempt service_output normalized_output requested_state
  requested_state="$(hana_requested_state)"
  if [[ "$requested_state" == running ]]; then
    log "${HANA_INSTANCE} is al aangezet; geen startopdracht nodig."
  else
    if [[ "$requested_state" == stopped ]]; then
      log "${HANA_INSTANCE} staat uit en wordt gestart."
    else
      log "Actuele HANA-status is onbekend; veilige startopdracht wordt uitgevoerd."
    fi
    log "Startopdracht voor ${HANA_INSTANCE} versturen."
    if ! run_cf update-service "${HANA_INSTANCE}" \
      -c '{"data":{"serviceStopped":false}}' >/dev/null; then
      log "FOUT: startopdracht voor ${HANA_INSTANCE} is mislukt."
      return 1
    fi
  fi

  # Ook wanneer serviceStopped al false was, kan een eerdere start nog bezig
  # zijn. Controleer daarom altijd de brokerstatus voordat apps worden gestart.
  for ((attempt = 1; attempt <= HANA_MAX_CHECKS; attempt++)); do
    if ! service_output="$(run_cf service "${HANA_INSTANCE}" 2>&1)"; then
      log "FOUT: status van ${HANA_INSTANCE} kon niet worden opgehaald."
      return 1
    fi
    normalized_output="$(printf '%s' "${service_output}" | normalize_output)"
    if grep -Eqi 'status:[[:space:]]+(create|update)[[:space:]]+succeeded' <<<"${normalized_output}"; then
      log "${HANA_INSTANCE} is succesvol gestart."
      return 0
    fi
    if grep -Eqi 'status:[[:space:]]+(create|update)[[:space:]]+(failed|error)' <<<"${normalized_output}"; then
      log "FOUT: de update van ${HANA_INSTANCE} is mislukt."
      return 1
    fi
    log "HANA-start loopt nog; controle ${attempt}/${HANA_MAX_CHECKS}."
    sleep "${HANA_CHECK_INTERVAL}"
  done
  log "FOUT: timeout tijdens wachten op ${HANA_INSTANCE}."
  return 1
}

start_app() {
  local app="$1" attempt app_output normalized_output action

  if ! app_output="$(run_cf app "${app}" 2>&1)"; then
    log "FOUT: status van ${app} kon niet worden opgehaald."
    return 1
  fi
  normalized_output="$(printf '%s' "${app_output}" | normalize_output)"
  if grep -Eqi 'requested state:[[:space:]]+started' <<<"${normalized_output}" &&
     grep -Eqi 'instances:[[:space:]]+1/1' <<<"${normalized_output}"; then
    log "${app} draait al gezond met 1/1 instance; geen actie nodig."
    return 0
  fi

  if grep -Eqi 'requested state:[[:space:]]+started' <<<"${normalized_output}"; then
    action="restart"
    log "${app} is aangezet maar niet gezond; app wordt herstart."
  else
    action="start"
    log "${app} staat uit en wordt gestart."
  fi

  if ! app_output="$(run_cf "$action" "${app}" 2>&1)"; then
    log "FOUT: ${action}-opdracht voor ${app} is mislukt."
    printf '%s\n' "${app_output}" >&2
    return 1
  fi

  for ((attempt = 1; attempt <= APP_MAX_CHECKS; attempt++)); do
    if ! app_output="$(run_cf app "${app}" 2>&1)"; then
      log "FOUT: status van ${app} kon niet worden opgehaald."
      return 1
    fi
    normalized_output="$(printf '%s' "${app_output}" | normalize_output)"
    if grep -Eqi 'requested state:[[:space:]]+started' <<<"${normalized_output}" &&
       grep -Eqi 'instances:[[:space:]]+1/1' <<<"${normalized_output}"; then
      log "${app} draait succesvol met 1/1 instance."
      return 0
    fi
    log "${app} start nog; controle ${attempt}/${APP_MAX_CHECKS}."
    sleep "${APP_CHECK_INTERVAL}"
  done

  log "FOUT: ${app} heeft niet binnen de wachttijd 1/1 bereikt."
  run_cf logs "${app}" --recent >&2 || true
  return 1
}

log "SAP HANA- en PlayNext-startcontrole begonnen."
if ! run_cf target -o "${CF_ORG}" -s "${CF_SPACE}" >/dev/null; then
  log "FOUT: Cloud Foundry-target kon niet worden ingesteld; de login is mogelijk verlopen."
  exit 1
fi
log "Cloud Foundry-target staat op org ${CF_ORG}, space ${CF_SPACE}."
start_hana
start_app "playnext-srv"
start_app "playnext"
mkdir -p "${STATE_DIR}"
date +%s >"${STATE_DIR}/last-online.epoch.tmp"
mv "${STATE_DIR}/last-online.epoch.tmp" "${STATE_DIR}/last-online.epoch"
printf 'up\n' >"${STATE_DIR}/last-status"
log "ExamDB, playnext-srv en playnext draaien succesvol."
