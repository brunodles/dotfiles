#!/usr/bin/env bash
# install_pihole — Download and run the official Pi-hole installer
# https://github.com/pi-hole/pi-hole/#one-step-automated-install

set -euo pipefail

if command -v pihole &>/dev/null; then
  echo "Pi-hole is already installed."
  pihole version
  exit 0
fi

echo "Installing Pi-hole..."
curl -sSL https://install.pi-hole.net | bash
