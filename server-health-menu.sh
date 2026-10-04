#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/menu-ui.sh"

while true; do
  print_menu_header "Ubuntu server health"
  echo "  1) Run general health check"
  echo "  2) Check Matter IPv6"
  echo "  3) Fix Matter IPv6 (reactivates network connection)"
  echo "  4) Show disk usage"
  echo "  5) Show recent system log entries"
  echo "  b) Back"
  echo "  q) Quit"
  echo
  read -r -p "Choose an option: " choice
  case "$choice" in
    1) "$ROOT/health-check.sh" || true; wait_for_menu_return ;;
    2) bash "$ROOT/server-scripts/check-ipv6-matter.sh" || true; wait_for_menu_return ;;
    3)
      echo "This changes NetworkManager and IPv6 settings and briefly reconnects the server."
      if confirm_action "Apply Matter IPv6 fix?"; then
        bash "$ROOT/server-scripts/fix-ipv6-matter.sh" || true
      fi
      wait_for_menu_return
      ;;
    4) df -h / /mnt/mediadisk; wait_for_menu_return ;;
    5) journalctl -n 100 --no-pager; wait_for_menu_return ;;
    b|B|"") exit 0 ;;
    q|Q) exit "$MENU_QUIT" ;;
    *) echo "Invalid choice."; wait_for_menu_return ;;
  esac
done
