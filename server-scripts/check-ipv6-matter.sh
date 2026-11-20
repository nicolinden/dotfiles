#!/usr/bin/env bash
set -euo pipefail

IFACE="${1:-enp3s0f0}"
LAN_PREFIX="${2:-fdc7:5a91:2e48:1:}"

if [[ "$(sysctl -n net.ipv6.conf.all.disable_ipv6)" != "0" ||
      "$(sysctl -n "net.ipv6.conf.${IFACE}.disable_ipv6")" != "0" ]]; then
  echo "FOUT: IPv6 staat uit op de server of op $IFACE"
  exit 1
fi

if ! ip -6 addr show dev "$IFACE" scope global |
     grep -Eqi "inet6[[:space:]]+${LAN_PREFIX}"; then
  echo "FOUT: $IFACE heeft geen adres uit de lokale IPv6-prefix $LAN_PREFIX"
  exit 1
fi

echo "OK: lokale IPv6 is actief op $IFACE"
exit 0
