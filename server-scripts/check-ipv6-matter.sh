#!/usr/bin/env bash
set -euo pipefail

connection="${1:-netplan-enp3s0f0}"
interface="${2:-enp3s0f0}"

method="$(nmcli -g ipv6.method connection show "$connection" 2>/dev/null || true)"
if [[ "$method" != auto ]] ||
   [[ "$(sysctl -n net.ipv6.conf.all.disable_ipv6)" != 0 ]] ||
   [[ "$(sysctl -n "net.ipv6.conf.${interface}.disable_ipv6")" != 0 ]] ||
   ! ip -6 addr show dev "$interface" scope global | grep -q inet6 ||
   ! ip -6 route | grep -q "^default .* dev ${interface}" ||
   ! ip -6 route | grep -q "^fd.* dev ${interface}"; then
  echo "Matter IPv6: niet volledig actief op $interface"
  exit 1
fi
echo "Matter IPv6: actief op $interface"
