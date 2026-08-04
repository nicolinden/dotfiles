#!/usr/bin/env bash

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh"

TAILSCALE_APP="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

tailscale_json() {
  if [[ -x "$TAILSCALE_APP" ]]; then
    TAILSCALE_BE_CLI=1 "$TAILSCALE_APP" status --json 2>/dev/null
  fi
}

update_tailscale() {
  local status_json backend tailscale_color

  status_json="$(tailscale_json)"
  backend="$(printf '%s' "$status_json" | jq -r '.BackendState // "Stopped"' 2>/dev/null)"

  if [[ "$backend" == "Running" ]]; then
    tailscale_color="$GREEN"
  else
    tailscale_color="$GREY"
  fi

  sketchybar --set tailscale icon.color="$tailscale_color"
}

update_connections() {
  local wifi_device wifi_ip wifi_name wifi_label
  local ethernet_devices ethernet_device ethernet_ip ethernet_label
  local network_icon network_color

  wifi_device="$(networksetup -listallhardwareports 2>/dev/null \
    | awk '/Hardware Port: Wi-Fi/{getline; print $2; exit}')"
  wifi_ip="$(ipconfig getifaddr "$wifi_device" 2>/dev/null || true)"
  wifi_name="$(networksetup -getairportnetwork "$wifi_device" 2>/dev/null \
    | sed 's/^Current Wi-Fi Network: //')"
  if [[ -n "$wifi_ip" ]]; then
    [[ "$wifi_name" == *"not associated"* ]] && wifi_name="Connected"
    wifi_label="Wi-Fi: ${wifi_name:-Connected} · $wifi_device · $wifi_ip"
  else
    wifi_label="Wi-Fi: Disconnected"
  fi

  ethernet_devices="$(networksetup -listallhardwareports 2>/dev/null \
    | awk '/Hardware Port: Ethernet/{getline; print $2}')"
  ethernet_ip=""
  ethernet_label="Ethernet: Disconnected"
  while IFS= read -r ethernet_device; do
    [[ -n "$ethernet_device" ]] || continue
    ethernet_ip="$(ipconfig getifaddr "$ethernet_device" 2>/dev/null || true)"
    if [[ -n "$ethernet_ip" ]]; then
      ethernet_label="Ethernet: Connected · $ethernet_device · $ethernet_ip"
      break
    fi
  done <<< "$ethernet_devices"

  if [[ -n "$ethernet_ip" ]]; then
    network_icon="󰈀"
    network_color="$GREEN"
  elif [[ -n "$wifi_ip" ]]; then
    network_icon="󰖩"
    network_color="$BLUE"
  else
    network_icon="󰖪"
    network_color="$GREY"
  fi

  sketchybar --set network icon="$network_icon" icon.color="$network_color" \
             --set network.wifi label="$wifi_label" \
             --set network.ethernet label="$ethernet_label"
}

toggle_tailscale() {
  local status_json backend

  [[ -x "$TAILSCALE_APP" ]] || {
    open -a Tailscale
    return
  }

  status_json="$(tailscale_json)"
  backend="$(printf '%s' "$status_json" | jq -r '.BackendState // "Stopped"' 2>/dev/null)"
  if [[ "$backend" == "Running" ]]; then
    TAILSCALE_BE_CLI=1 "$TAILSCALE_APP" down >/dev/null 2>&1
  else
    TAILSCALE_BE_CLI=1 "$TAILSCALE_APP" up >/dev/null 2>&1
  fi
  update_tailscale
}

open_wifi_settings() {
  sketchybar --set network popup.drawing=off
  open "x-apple.systempreferences:com.apple.wifi-settings-extension" 2>/dev/null \
    || open -a "System Settings"
}

case "${1:-}" in
  toggle-tailscale)
    toggle_tailscale
    ;;
  open-wifi-settings)
    open_wifi_settings
    ;;
  *)
    case "${NAME:-network}:${SENDER:-routine}" in
      network:mouse.clicked) sketchybar --set network popup.drawing=toggle ;;
      network:mouse.exited.global) sketchybar --set network popup.drawing=off ;;
      tailscale:*) update_tailscale ;;
      network:*) update_connections ;;
      *)
        update_tailscale
        update_connections
        ;;
    esac
    ;;
esac
