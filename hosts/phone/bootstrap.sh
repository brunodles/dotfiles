#!/data/data/com.termux/files/usr/bin/bash
# bootstrap.sh — Run the full bootstrap for phone (terminal client)
# Usage: cd ~/dotfiles && bash hosts/phone/bootstrap.sh
set -euo pipefail

cd "$(dirname "$0")/bootstrap"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📱 Phone/Terminal bootstrap"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

bash install.sh
bash configure.sh
bash links.sh

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Phone bootstrap complete!"
echo "  ➜  Restart Termux or run 'zsh'"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
