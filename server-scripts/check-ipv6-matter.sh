#!/usr/bin/env bash
set -euo pipefail

connection="${1:-netplan-enp3s0f0}"
interface="${2:-enp3s0f0}"

failures=0
problem() {
  printf '  - %s\n' "$1"
  failures=$((failures + 1))
}

method="$(nmcli -g ipv6.method connection show "$connection" 2>/dev/null || true)"
[[ "$method" == auto ]] || problem "NetworkManager: ipv6.method voor $connection is '${method:-onbekend}' (verwacht auto)"

for setting in all "$interface"; do
  value="$(sysctl -n "net.ipv6.conf.${setting}.disable_ipv6" 2>/dev/null || true)"
  [[ "$value" == 0 ]] || problem "IPv6 staat uit voor $setting (disable_ipv6=${value:-onbekend})"
done

if ! ip -6 addr show dev "$interface" scope global 2>/dev/null | grep 'inet6 ' >/dev/null; then
  problem "Geen globaal IPv6-adres op $interface"
fi
if ! ip -6 route show default dev "$interface" 2>/dev/null | grep '^default ' >/dev/null; then
  problem "Geen IPv6-standaardroute via $interface"
fi
if ! ip -6 route show dev "$interface" 2>/dev/null | grep -E '^fd[[:xdigit:]]*:' >/dev/null; then
  problem "Geen ULA-route (fd00::/8) via $interface"
fi

if (( failures > 0 )); then
  echo "Matter IPv6: niet volledig actief op $interface ($failures controle(s) mislukt)"
  exit 1
fi
echo "Matter IPv6: actief op $interface"
