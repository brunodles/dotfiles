#!/usr/bin/env bash
# sshuttle.sh — Temporary VPN tunnel over SSH
#
# Useful during initial bootstrap, before Tailscale is configured.
# Runs on the CLIENT (the machine that needs the tunnel).
# The server only needs SSH + a user with login access.
#
# Usage:
#   bash scripts/vpn/sshuttle.sh user@host [--daemon]
#
# Examples:
#   bash scripts/vpn/sshuttle.sh bruno@vps
#   bash scripts/vpn/sshuttle.sh bruno@vps --daemon
#
# Stop (foreground mode): Ctrl+C
# Stop (daemon mode):     sshuttle --stop  (or kill $PID)

set -euo pipefail

SERVER="${1:?Usage: sshuttle.sh user@host [--daemon]}"
shift || true

# ── Install sshuttle if missing ──
if ! command -v sshuttle &>/dev/null; then
  echo "sshuttle not found. Installing..."
  pip3 install --user sshuttle
fi

# sshuttle may land in ~/.local/bin after --user install
if ! command -v sshuttle &>/dev/null; then
  export PATH="$HOME/.local/bin:$PATH"
fi

# ── Establish tunnel ──
echo "Connecting tunnel via $SERVER ..."
sshuttle -r "$SERVER" 0.0.0.0/0 --dns "$@"
