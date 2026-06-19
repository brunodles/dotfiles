#!/usr/bin/env bash
# bootstrap.sh — Setup Raspberry Pi for Pi-hole + Tailscale
#
# Usage:
#   ssh pi@<ip> 'bash -s' < bootstrap.sh
#   # or copy it over and run locally on the Pi

set -euo pipefail
trap 'echo "❌ Error on line ${LINENO}" >&2' ERR

install_path="$HOME/dotfiles/install"

if [[ ! -d "$install_path" ]]; then
  echo "Error: dotfiles repo not found at $HOME/dotfiles" >&2
  echo "Clone it first:" >&2
  echo "  git clone https://github.com/brunodles/dotfiles.git" >&2
  exit 1
fi

# ── System bootstrap ─────────────────────────────────────────
echo "=== System packages ==="
"$install_path/ubuntu/bootstrap.sh"

# ── Tailscale ─────────────────────────────────────────────────
echo "=== Tailscale ==="
"$install_path/_tailscale.sh"

# ── Pi-hole ───────────────────────────────────────────────────
echo "=== Pi-hole ==="
"$install_path/_pihole.sh"

# ── Restore saved configuration ───────────────────────────────
echo "=== Restoring Pi-hole config ==="
restore_script="$HOME/dotfiles/host/pi/pihole/scripts/restore-config.sh"
if [[ -f "$restore_script" ]]; then
  bash "$restore_script"
else
  echo "  ⚠️  restore-config.sh not found. Run it later from the repo."
fi

echo ""
echo "✅ Pi setup complete."
echo ""
echo "Next steps:"
echo "  1. Authenticate Tailscale:  sudo tailscale up"
echo "  2. Set Pi-hole web password:  pihole -a -p"
echo "  3. Access admin panel:  http://$(hostname -I | awk '{print $1}')/admin"
