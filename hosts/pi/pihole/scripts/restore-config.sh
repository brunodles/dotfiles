#!/usr/bin/env bash
#
# restore-config.sh — Apply saved Pi-hole configuration to a (fresh) instance
#
# Usage:
#   ./restore-config.sh
#
# This script reads files from ../extracted/ and applies them to the
# local Pi-hole installation. Run it directly on the Raspberry Pi.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXTRACTED_DIR="$(cd "$SCRIPT_DIR/../extracted" && pwd)"

if [[ ! -d "$EXTRACTED_DIR" ]]; then
  echo "Error: extracted config directory not found at $EXTRACTED_DIR" >&2
  echo "Run extract-config.sh first or check the path." >&2
  exit 1
fi

echo "🔧 Restoring Pi-hole config from $EXTRACTED_DIR ..."
echo ""

# ── Main config ──────────────────────────────────────────────
if [[ -f "$EXTRACTED_DIR/setupVars.conf" ]]; then
  echo "  [1/6] Restoring setupVars.conf ..."
  sudo cp "$EXTRACTED_DIR/setupVars.conf" /etc/pihole/setupVars.conf
  echo "    ✅ Restored. Run 'pihole setup' to apply interactively,"
  echo "       or 'pihole -r' to reconfigure from saved vars."
fi

# ── Adlists ──────────────────────────────────────────────────
if [[ -f "$EXTRACTED_DIR/adlists.list" ]]; then
  echo "  [2/6] Restoring adlists.list ..."
  # Pi-hole v5+: adlists.list is read by pihole -g
  sudo cp "$EXTRACTED_DIR/adlists.list" /etc/pihole/adlists.list
  echo "    ✅ Restored. Run 'pihole -g' to update gravity."
fi

# ── Whitelist ────────────────────────────────────────────────
if [[ -f "$EXTRACTED_DIR/whitelist.txt" ]]; then
  echo "  [3/6] Restoring whitelist ..."
  while IFS= read -r domain; do
    [[ -z "$domain" || "$domain" == \#* ]] && continue
    pihole -w -q -d "$domain" > /dev/null 2>&1 || true
  done < "$EXTRACTED_DIR/whitelist.txt"
  echo "    ✅ Whitelist entries restored."
fi

# ── Blacklist ────────────────────────────────────────────────
if [[ -f "$EXTRACTED_DIR/blacklist.txt" ]]; then
  echo "  [4/6] Restoring blacklist ..."
  while IFS= read -r domain; do
    [[ -z "$domain" || "$domain" == \#* ]] && continue
    pihole -b -q -d "$domain" > /dev/null 2>&1 || true
  done < "$EXTRACTED_DIR/blacklist.txt"
  echo "    ✅ Blacklist entries restored."
fi

# ── Regex filters ────────────────────────────────────────────
if [[ -f "$EXTRACTED_DIR/regex.list" ]]; then
  echo "  [5/6] Restoring regex filters ..."
  sudo cp "$EXTRACTED_DIR/regex.list" /etc/pihole/regex.list
  echo "    ✅ Regex filters restored."
fi

# ── Local DNS records ────────────────────────────────────────
if [[ -f "$EXTRACTED_DIR/custom.list" ]]; then
  echo "  [6/6] Restoring local DNS records ..."
  sudo cp "$EXTRACTED_DIR/custom.list" /etc/pihole/custom.list
  echo "    ✅ Local DNS records restored."
fi

# ── Finalise ─────────────────────────────────────────────────
echo ""
echo "⚙️  Regenerating gravity database ..."
pihole -g

echo ""
echo "✅ Restore complete."
echo "   Reboot the Pi or restart Pi-hole to ensure everything is applied."
