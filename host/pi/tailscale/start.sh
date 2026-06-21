#!/usr/bin/env bash
# start.sh — Join Pi to tailnet as a subnet router
#
# Usage:
#   TS_AUTHKEY=tskey-... PI_SUBNET=42 sudo -E ./start.sh
#
# Sources TS_AUTHKEY and PI_SUBNET from:
#   1. Environment variables
#   2. .env file in the same directory
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"

[[ -f "$SCRIPT_DIR/.env" ]] && source "$SCRIPT_DIR/.env"

SUBNET="${PI_SUBNET:-${SUBNET:-X}}"

# Install tailscale if missing
bash "$DOTFILES/install/_tailscale.sh"

# Enable IP forwarding (required for subnet routing)
if [[ "$(sysctl -n net.ipv4.ip_forward)" != "1" ]]; then
  sysctl -w net.ipv4.ip_forward=1
  echo "net.ipv4.ip_forward=1" >/etc/sysctl.d/99-tailscale.conf
fi

# Idempotent tailscale up — same flags = no-op
ARGS="--advertise-routes=192.168.${SUBNET}.0/24"
[[ -n "${TS_AUTHKEY:-}" ]] && ARGS="$ARGS --authkey=$TS_AUTHKEY"

tailscale up $ARGS

tailscale status
