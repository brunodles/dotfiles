#!/usr/bin/env bash
# bootstrap.sh — Run the full macOS work bootstrap
set -euo pipefail

cd "$(dirname "$0")/bootstrap"
bash install.sh
bash configure.sh
bash links.sh
echo "Work macOS bootstrap complete"
