#!/usr/bin/env bash
# bootstrap.sh — Run the full silver desktop bootstrap
set -euo pipefail

cd "$(dirname "$0")/bootstrap"
bash install.sh
bash links.sh

echo "Silver desktop bootstrap complete"
