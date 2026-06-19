#!/usr/bin/env bash
#
# bootstrap.sh — Setup a Raspberry Pi for Pi-hole
#
# Usage:
#   ssh pi@<ip> 'bash -s' < bootstrap.sh
#   # or copy it over and run locally on the Pi

set -euo pipefail

echo "⚠️  Pi-hole is not yet set up via this repository."
echo "   This script will be completed once the Pi is on the network."
echo ""
echo "   For now, run regular Pi-hole install:"
echo "     curl -sSL https://install.pi-hole.net | bash"
echo ""
echo "   Then restore config with:"
echo "     pihole/scripts/restore-config.sh"
