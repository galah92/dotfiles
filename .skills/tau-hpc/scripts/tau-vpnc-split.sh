#!/usr/bin/env bash
set -euo pipefail

VPNC_SCRIPT=""
if [ -x /usr/share/vpnc-scripts/vpnc-script ]; then
  VPNC_SCRIPT=/usr/share/vpnc-scripts/vpnc-script
elif [ -x /etc/vpnc/vpnc-script ]; then
  VPNC_SCRIPT=/etc/vpnc/vpnc-script
else
  echo "vpnc-script not found in /usr/share/vpnc-scripts or /etc/vpnc" >&2
  exit 1
fi

# Force split tunneling:
# - Route TAU core network via VPN.
# - Include both 132.66/16 and 132.67/16 to cover cs.tau.ac.il servers.
# - Optional host overrides can be provided with TAU_EXTRA_VPN_HOSTS.
split_idx=0

add_split_route() {
  local addr="$1"
  local mask="$2"
  local masklen="$3"
  export "CISCO_SPLIT_INC_${split_idx}_ADDR=${addr}"
  export "CISCO_SPLIT_INC_${split_idx}_MASK=${mask}"
  export "CISCO_SPLIT_INC_${split_idx}_MASKLEN=${masklen}"
  export "CISCO_SPLIT_INC_${split_idx}_PROTOCOL=0"
  export "CISCO_SPLIT_INC_${split_idx}_SPORT=0"
  export "CISCO_SPLIT_INC_${split_idx}_DPORT=0"
  split_idx=$((split_idx + 1))
}

add_host_routes() {
  local host="$1"
  local ip
  while read -r ip; do
    [ -n "${ip}" ] || continue
    add_split_route "${ip}" "255.255.255.255" "32"
  done < <(getent ahostsv4 "${host}" 2>/dev/null | awk '{print $1}' | sort -u)
}

add_split_route "132.66.0.0" "255.255.0.0" "16"
add_split_route "132.67.0.0" "255.255.0.0" "16"
for host in ${TAU_EXTRA_VPN_HOSTS:-}; do
  add_host_routes "${host}"
done

export CISCO_SPLIT_INC="${split_idx}"

exec "$VPNC_SCRIPT" "$@"
