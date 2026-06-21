#!/data/data/com.termux/files/usr/bin/bash
# bootstrap.sh — Run the full Android/Termux bootstrap
set -euo pipefail

cd "$(dirname "$0")/bootstrap"
bash install.sh
bash configure.sh
bash links.sh
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Android/Termux bootstrap complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
