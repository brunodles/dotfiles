#!/usr/bin/env bash
# bootstrap.sh — Run the full media server bootstrap
set -euo pipefail

cd "$(dirname "$0")/bootstrap"

bash install.sh
bash configure.sh
bash links.sh

$BOOTSTRAP_DIR/stacks-up

echo "Media server bootstrap complete"
