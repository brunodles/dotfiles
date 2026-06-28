#!/usr/bin/env bash
# bootstrap.sh — Run the full VPS bootstrap
set -euo pipefail

cd "$(dirname "$0")/bootstrap"
bash install.sh
bash provision.sh
bash links.sh

$BOOTSTRAP_DIR/stacks-up
echo "VPS bootstrap complete"
