#!/usr/bin/env bash
# bootstrap.sh — Run the full VPS bootstrap
set -euo pipefail

cd "$(dirname "$0")/bootstrap"
bash install.sh
bash configure.sh
bash links.sh
echo "VPS bootstrap complete"
