#!/usr/bin/env bash
# Install Tailscale
# https://tailscale.com/download

set -euo pipefail

if command -v tailscale &>/dev/null; then
  echo "Tailscale is already installed."
  tailscale version
  exit 0
fi

# Detect Termux (Android)
if [[ -d /data/data/com.termux ]]; then
  echo "Detected Termux. Installing via pkg..."
  pkg install tailscale -y
  exit $?
fi

# Linux (Debian/Ubuntu/Raspbian)
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  echo "Detected $ID. Installing via official script..."
  curl -fsSL https://tailscale.com/install.sh | sh
  exit $?
fi

echo "Unsupported OS. Please install Tailscale manually: https://tailscale.com/download"
exit 1
