#!/usr/bin/env bash
set -euo pipefail

connection="${1:-netplan-enp3s0f0}"
interface="${2:-enp3s0f0}"
check_script="$(dirname "$0")/check-ipv6-matter.sh"

if "$check_script" "$interface" >/dev/null; then
  echo "OK: lokale IPv6 werkt al op $interface; niets gewijzigd."
  exit 0
fi

echo "Lokale IPv6-check faalt. Herstel van $connection / $interface..."
echo "Let op: de netwerkverbinding kan tijdens dit herstel kort wegvallen."

sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0 >/dev/null
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=0 >/dev/null
sudo sysctl -w "net.ipv6.conf.${interface}.disable_ipv6=0" >/dev/null

sudo tee /etc/sysctl.d/99-ipv6-enabled.conf >/dev/null <<EOF
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.${interface}.disable_ipv6 = 0
EOF

sudo nmcli connection modify "$connection" \
  ipv6.method auto \
  ipv6.ignore-auto-routes no

sudo nmcli connection up "$connection" >/dev/null
sleep 5
"$check_script" "$interface"
