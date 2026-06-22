#!/usr/bin/env bash
# Install Homebrew + base packages on macOS
# https://brew.sh

set -euo pipefail

if command -v brew &>/dev/null; then
  echo "Homebrew is already installed."
  brew --version
else
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo ""
echo "✅ Homebrew setup complete."
