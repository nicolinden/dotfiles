#!/usr/bin/env bash

# Install and operate the server-only SAP HANA Trial tools and health monitor.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$DOTFILES_DIR/sap-hana"
RUNTIME_DIR="$HOME/.local/share/sap-hana-automation"
source "$DOTFILES_DIR/menu-ui.sh"

[[ "$(uname -s)" == Linux ]] || { echo "SAP HANA Trial management is available on Linux only."; exit 1; }

automation_is_running() {
  systemctl is-active --quiet sap-hana-start.service
}

require_automation_idle() {
  if automation_is_running; then
    echo "The HANA / PlayNext start task is currently running. Wait for it to finish first."
    return 1
  fi
}

install_automation() {
  local tmp_dir current_user current_group webhook
  require_automation_idle || return
  command -v docker >/dev/null 2>&1 || { echo "Docker is required."; return 1; }
  command -v python3 >/dev/null 2>&1 || { echo "Python 3 is required for safe webhook messages."; return 1; }
  current_user="$(id -un)"
  current_group="$(id -gn)"
  mkdir -p "$RUNTIME_DIR"

  install -m 0755 "$SOURCE_DIR/start-hana.sh" "$RUNTIME_DIR/start-hana.sh"
  install -m 0755 "$SOURCE_DIR/check-sap.sh" "$RUNTIME_DIR/check-sap.sh"
  install -m 0755 "$SOURCE_DIR/login-sap.sh" "$RUNTIME_DIR/login-sap.sh"
  install -m 0755 "$SOURCE_DIR/logs-sap.sh" "$RUNTIME_DIR/logs-sap.sh"
  install -m 0755 "$SOURCE_DIR/monitor-health.sh" "$RUNTIME_DIR/monitor-health.sh"
  install -m 0755 "$SOURCE_DIR/notify-ha.sh" "$RUNTIME_DIR/notify-ha.sh"
  install -m 0644 "$SOURCE_DIR/compose.yaml" "$RUNTIME_DIR/compose.yaml"
  mkdir -p "$RUNTIME_DIR/state"
  chmod 700 "$RUNTIME_DIR/state"

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
  sed -e "s|@USER@|$current_user|g" -e "s|@GROUP@|$current_group|g" -e "s|@HOME@|$HOME|g" \
    "$SOURCE_DIR/systemd/sap-hana-health.service.in" >"$tmp_dir/sap-hana-health.service"
  sudo install -m 0644 "$tmp_dir/sap-hana-start.service" /etc/systemd/system/sap-hana-start.service
  sudo install -m 0644 "$tmp_dir/sap-hana-failure-notification.service" /etc/systemd/system/sap-hana-failure-notification.service
  sudo install -m 0644 "$tmp_dir/sap-hana-health.service" /etc/systemd/system/sap-hana-health.service
  sudo install -m 0644 "$SOURCE_DIR/systemd/sap-hana-health.timer" /etc/systemd/system/sap-hana-health.timer
  sudo systemctl disable --now sap-hana-start.timer 2>/dev/null || true
  sudo rm -f /etc/systemd/system/sap-hana-start.timer
  sudo systemctl daemon-reload
  sudo systemctl reset-failed sap-hana-start.service 2>/dev/null || true
  sudo systemctl enable --now sap-hana-health.timer
  echo "SAP HANA tools installed/updated. Automatic startup is disabled; the read-only health monitor is active."
}

require_runtime() {
  if [[ ! -x "$RUNTIME_DIR/check-sap.sh" ]] || [[ ! -f "$RUNTIME_DIR/compose.yaml" ]]; then
    echo "SAP HANA Trial automation is not installed yet. Choose Install / update first."
    return 1
  fi
}

runtime_is_current() {
  local file
  require_runtime >/dev/null 2>&1 || return 1
  for file in start-hana.sh check-sap.sh login-sap.sh logs-sap.sh monitor-health.sh notify-ha.sh compose.yaml; do
    cmp -s "$SOURCE_DIR/$file" "$RUNTIME_DIR/$file" || return 1
  done
}

require_current_runtime() {
  require_runtime || return
  if ! runtime_is_current; then
    echo "The installed SAP HANA automation is older than the dotfiles version."
    echo "Choose Install / update automation first; notification.env will be preserved."
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
    echo "  1) Manual HANA / PlayNext start log"
    echo "  2) Home Assistant notification log"
    echo "  3) Background health-check log and next run"
    echo "  4) playnext-srv recent Cloud Foundry log"
    echo "  5) playnext recent Cloud Foundry log"
    echo "  b) Back"
    echo
    read -r -p "Choose an option: " log_choice
    case "$log_choice" in
      1) "$RUNTIME_DIR/logs-sap.sh" start; wait_for_menu_return ;;
      2) "$RUNTIME_DIR/logs-sap.sh" notification; wait_for_menu_return ;;
      3)
        "$RUNTIME_DIR/logs-sap.sh" health
        echo
        systemctl status sap-hana-health.timer --no-pager -l || true
        systemctl list-timers sap-hana-health.timer --no-pager
        wait_for_menu_return
        ;;
      4) "$RUNTIME_DIR/logs-sap.sh" backend || true; wait_for_menu_return ;;
      5) "$RUNTIME_DIR/logs-sap.sh" frontend || true; wait_for_menu_return ;;
      b|B|"") return ;;
      *) echo "Invalid choice."; wait_for_menu_return ;;
    esac
  done
}

while true; do
  print_menu_header "SAP HANA Trial"
  if [[ -d "$RUNTIME_DIR" ]] && ! runtime_is_current; then
    echo "  ! Update available: install the current dotfiles automation first."
    echo
  fi
  echo "  1) Install / update tools and background check"
  echo "  2) Show complete status overview"
  echo "  3) Start HANA and PlayNext now"
  echo "  4) Renew SAP SSO login"
  echo "  5) Send test notification"
  echo "  6) Logs and health-check status"
  echo "  b) Back"
  echo
  read -r -p "Choose an option: " choice
  case "$choice" in
    1) install_automation; wait_for_menu_return ;;
    2) require_current_runtime && "$RUNTIME_DIR/check-sap.sh" || true; wait_for_menu_return ;;
    3)
      if require_current_runtime; then
        if automation_is_running; then
          echo "The HANA / PlayNext start task is already running; no second run was started."
          sudo systemctl status sap-hana-start.service --no-pager -l || true
        else
          sudo systemctl start sap-hana-start.service
          sudo systemctl status sap-hana-start.service --no-pager -l
        fi
      fi
      wait_for_menu_return
      ;;
    4) require_runtime && require_automation_idle && "$RUNTIME_DIR/login-sap.sh" || true; wait_for_menu_return ;;
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
