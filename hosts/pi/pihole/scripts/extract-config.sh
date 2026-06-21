#!/usr/bin/env bash
#
# extract-config.sh — Pull Pi-hole configuration from a remote Raspberry Pi
#
# Usage:
#   ./extract-config.sh <user>@<hostname>
#
# Example:
#   ./extract-config.sh pi@192.168.1.10
#
# This script connects to a running Pi-hole instance via SSH and downloads
# all relevant configuration files into ../extracted/.

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $(basename "$0") <user>@<hostname>" >&2
  echo "  e.g. $(basename "$0") pi@192.168.1.10" >&2
  exit 1
fi

REMOTE="$1"
OUTPUT_DIR="$(cd "$(dirname "$0")/../extracted" && pwd)"
mkdir -p "$OUTPUT_DIR"

echo "🔍 Extracting Pi-hole config from $REMOTE ..."
echo "   Output: $OUTPUT_DIR"
echo ""

# ── Main config ──────────────────────────────────────────────
echo "  [1/6] setupVars.conf"
scp "$REMOTE:/etc/pihole/setupVars.conf" "$OUTPUT_DIR/" 2>/dev/null \
  || echo "    ⚠️  Not found (maybe permissions or wrong path)"

# ── Adlists (blocklist URLs) ─────────────────────────────────
echo "  [2/6] adlists.list"
scp "$REMOTE:/etc/pihole/adlists.list" "$OUTPUT_DIR/" 2>/dev/null \
  || ssh "$REMOTE" "pihole adlist list" > "$OUTPUT_DIR/adlists.list" 2>/dev/null \
  || echo "    ⚠️  Could not retrieve adlists"

# ── Whitelist / Blacklist ────────────────────────────────────
echo "  [3/6] whitelist.txt"
scp "$REMOTE:/etc/pihole/whitelist.txt" "$OUTPUT_DIR/" 2>/dev/null \
  || ssh "$REMOTE" "pihole -w -l" > "$OUTPUT_DIR/whitelist.txt" 2>/dev/null \
  || echo "    ⚠️  Could not retrieve whitelist"

echo "  [4/6] blacklist.txt"
scp "$REMOTE:/etc/pihole/blacklist.txt" "$OUTPUT_DIR/" 2>/dev/null \
  || ssh "$REMOTE" "pihole -b -l" > "$OUTPUT_DIR/blacklist.txt" 2>/dev/null \
  || echo "    ⚠️  Could not retrieve blacklist"

# ── Regex filters ────────────────────────────────────────────
echo "  [5/6] regex.list"
scp "$REMOTE:/etc/pihole/regex.list" "$OUTPUT_DIR/" 2>/dev/null \
  || ssh "$REMOTE" "pihole regex list" > "$OUTPUT_DIR/regex.list" 2>/dev/null \
  || echo "    ⚠️  Could not retrieve regex list"

# ── Local DNS records ────────────────────────────────────────
echo "  [6/6] custom.list + local.list"
scp "$REMOTE:/etc/pihole/custom.list" "$OUTPUT_DIR/" 2>/dev/null \
  || echo "    ⚠️  No custom.list found"
scp "$REMOTE:/etc/pihole/local.list" "$OUTPUT_DIR/" 2>/dev/null \
  || echo "    ⚠️  No local.list found"

echo ""
echo "✅ Extraction complete."
ls -la "$OUTPUT_DIR/"
