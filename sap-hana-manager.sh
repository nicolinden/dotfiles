#!/usr/bin/env bash

# Install and operate the server-only SAP HANA Trial automation.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$DOTFILES_DIR/sap-hana"
RUNTIME_DIR="$HOME/.local/share/sap-hana-automation"
source "$DOTFILES_DIR/menu-ui.sh"

[[ "$(uname -s)" == Linux ]] || { echo "SAP HANA Trial management is available on Linux only."; exit 1; }

install_automation() {
  local tmp_dir current_user current_group webhook
  command -v docker >/dev/null 2>&1 || { echo "Docker is required."; return 1; }
  current_user="$(id -un)"
  current_group="$(id -gn)"
  mkdir -p "$RUNTIME_DIR"

  install -m 0755 "$SOURCE_DIR/start-hana.sh" "$RUNTIME_DIR/start-hana.sh"
  install -m 0755 "$SOURCE_DIR/check-sap.sh" "$RUNTIME_DIR/check-sap.sh"
  install -m 0755 "$SOURCE_DIR/login-sap.sh" "$RUNTIME_DIR/login-sap.sh"
  install -m 0644 "$SOURCE_DIR/compose.yaml" "$RUNTIME_DIR/compose.yaml"

  if [[ ! -f "$RUNTIME_DIR/notification.env" ]]; then
    read -r -s -p "Home Assistant failure webhook URL: " webhook
    echo
    [[ -n "$webhook" ]] || { echo "A webhook URL is required."; return 1; }
    umask 077
    printf 'SAP_FAILURE_WEBHOOK_URL=%s\n' "$webhook" >"$RUNTIME_DIR/notification.env"
  fi
  chmod 600 "$RUNTIME_DIR/notification.env"

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN
  sed -e "s|@USER@|$current_user|g" -e "s|@GROUP@|$current_group|g" -e "s|@HOME@|$HOME|g" \
    "$SOURCE_DIR/systemd/sap-hana-start.service.in" >"$tmp_dir/sap-hana-start.service"
  sed -e "s|@USER@|$current_user|g" -e "s|@GROUP@|$current_group|g" -e "s|@HOME@|$HOME|g" \
    "$SOURCE_DIR/systemd/sap-hana-failure-notification.service.in" >"$tmp_dir/sap-hana-failure-notification.service"
  sudo install -m 0644 "$tmp_dir/sap-hana-start.service" /etc/systemd/system/sap-hana-start.service
  sudo install -m 0644 "$tmp_dir/sap-hana-failure-notification.service" /etc/systemd/system/sap-hana-failure-notification.service
  sudo install -m 0644 "$SOURCE_DIR/systemd/sap-hana-start.timer" /etc/systemd/system/sap-hana-start.timer
  sudo systemctl daemon-reload
  sudo systemctl enable --now sap-hana-start.timer
  echo "SAP HANA Trial automation installed/updated; notification.env was preserved."
}

require_runtime() {
  if [[ ! -x "$RUNTIME_DIR/check-sap.sh" ]] || [[ ! -f "$RUNTIME_DIR/compose.yaml" ]]; then
    echo "SAP HANA Trial automation is not installed yet. Choose Install / update first."
    return 1
  fi
}

run_cf() {
  docker compose --project-directory "$RUNTIME_DIR" \
    --file "$RUNTIME_DIR/compose.yaml" run --rm -T cf "$@"
}

show_logs_menu() {
  local log_choice
  require_runtime || return

  while true; do
    print_menu_header "SAP HANA Trial logs"
    echo "  1) HANA / PlayNext automation log"
    echo "  2) Failure notification log"
    echo "  3) Timer status and next run"
    echo "  4) playnext-srv recent Cloud Foundry log"
    echo "  5) playnext recent Cloud Foundry log"
    echo "  b) Back"
    echo
    read -r -p "Choose an option: " log_choice
    case "$log_choice" in
      1) sudo journalctl -u sap-hana-start.service -n 150 --no-pager -o cat; wait_for_menu_return ;;
      2) sudo journalctl -u sap-hana-failure-notification.service -n 100 --no-pager -o cat; wait_for_menu_return ;;
      3)
        systemctl status sap-hana-start.timer --no-pager -l || true
        echo
        systemctl list-timers sap-hana-start.timer --no-pager
        wait_for_menu_return
        ;;
      4) run_cf logs playnext-srv --recent; wait_for_menu_return ;;
      5) run_cf logs playnext --recent; wait_for_menu_return ;;
      b|B|"") return ;;
      *) echo "Invalid choice."; wait_for_menu_return ;;
    esac
  done
}

while true; do
  print_menu_header "SAP HANA Trial"
  echo "  1) Install / update automation"
  echo "  2) Check HANA instance and PlayNext apps"
  echo "  3) Start HANA and PlayNext now"
  echo "  4) Renew SAP SSO login"
  echo "  5) Send test notification"
  echo "  6) Logs and timer status"
  echo "  b) Back"
  echo
  read -r -p "Choose an option: " choice
  case "$choice" in
    1) install_automation; wait_for_menu_return ;;
    2) require_runtime && "$RUNTIME_DIR/check-sap.sh" || true; wait_for_menu_return ;;
    3)
      if require_runtime; then
        sudo systemctl start sap-hana-start.service
        sudo systemctl status sap-hana-start.service --no-pager -l
      fi
      wait_for_menu_return
      ;;
    4) require_runtime && "$RUNTIME_DIR/login-sap.sh" || true; wait_for_menu_return ;;
    5)
      if require_runtime; then
        echo "Sending a test notification through the configured Home Assistant webhook..."
        if sudo systemctl start sap-hana-failure-notification.service; then
          echo "Test notification sent successfully."
        else
          echo "The test notification failed. Open Logs and timer status for details."
        fi
      fi
      wait_for_menu_return
      ;;
    6) show_logs_menu ;;
    b|B|"") exit 0 ;;
    *) echo "Invalid choice."; wait_for_menu_return ;;
  esac
done
