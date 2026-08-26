#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
run_cf() { docker compose --project-directory "$SCRIPT_DIR" --file "$SCRIPT_DIR/compose.yaml" run --rm -T cf "$@"; }

case "${1:-all}" in
  start) sudo journalctl -u sap-hana-start.service -n 150 --no-pager -o cat ;;
  health) sudo journalctl -u sap-hana-health.service -n 150 --no-pager -o cat ;;
  notification) sudo journalctl -u sap-hana-failure-notification.service -n 100 --no-pager -o cat ;;
  backend) run_cf logs playnext-srv --recent ;;
  frontend) run_cf logs playnext --recent ;;
  all)
    sudo journalctl -u sap-hana-start.service -u sap-hana-health.service \
      -u sap-hana-failure-notification.service -n 250 --no-pager -o cat
    ;;
  *) echo "Gebruik: $0 [all|start|health|notification|backend|frontend]" >&2; exit 2 ;;
esac
