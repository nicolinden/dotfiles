#!/usr/bin/env bash
set -euo pipefail

connection="${1:-netplan-enp3s0f0}"
interface="${2:-enp3s0f0}"

echo "IPv6 inschakelen en duurzaam configureren voor $connection / $interface..."
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0 >/dev/null
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=0 >/dev/null
sudo sysctl -w "net.ipv6.conf.${interface}.disable_ipv6=0" >/dev/null
sudo tee /etc/sysctl.d/99-ipv6-enabled.conf >/dev/null <<EOF
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.${interface}.disable_ipv6 = 0
EOF
sudo nmcli connection modify "$connection" \
  ipv6.method auto ipv6.ignore-auto-routes no \
  ipv6.ignore-auto-dns no ipv6.never-default no connection.autoconnect yes
sudo nmcli connection up "$connection" >/dev/null
sleep 5
"$(dirname "$0")/check-ipv6-matter.sh" "$connection" "$interface"
