#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if docker compose --project-directory "${SCRIPT_DIR}" \
  --file "${SCRIPT_DIR}/compose.yaml" run --rm cf login \
  -a https://api.cf.us10-001.hana.ondemand.com \
  -o 216fb3e1trial -s dev --sso; then
  printf '\nSSO-login is succesvol.\n'
  printf 'Test de volledige automatisering via het dotfiles-menu of met:\n\n'
  printf 'sudo systemctl start sap-hana-start.service\n'
else
  printf '\nFOUT: de SSO-login is niet gelukt.\n' >&2
  exit 1
fi
