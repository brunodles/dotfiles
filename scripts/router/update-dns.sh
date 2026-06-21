#!/usr/bin/env bash
# update-dns.sh — Update DNS servers on Askey RTF8115VW (Vivo)
#
# Uses the router's HTTP API via curl (no Selenium, no browser).
# Tested endpoints from community reverse-engineering (see references).
#
# Usage:
#   bash scripts/router/update-dns.sh <primary_dns> [secondary_dns]
#
# Environment:
#   ROUTER=192.168.15.1     Router IP (default)
#   PASSWORD=<admin_pass>   Router admin password (sticker)
#
# Examples:
#   PASSWORD=abc123 bash scripts/router/update-dns.sh 192.168.1.53
#   PASSWORD=abc123 ROUTER=192.168.15.1 \
#     bash scripts/router/update-dns.sh 192.168.1.53 192.168.1.54
#
# References:
#   https://github.com/edgardocorrea/modem-vivo        — API login flow
#   https://github.com/rogocal/movistar-router-automatizer — DNS page fields
#   https://github.com/superMDMArio/RTF8115VW           — SSH/ASPSH docs
#
# Methodology:
#   The router exposes an HTTP API. The admin interface uses ASP pages and
#   CGI handlers. Auth works via session cookie obtained from /login.asp
#   then POSTing credentials to /cgi-bin/te_acceso_router.cgi.
#   DNS settings live on /te_red_local.asp with fields DNSserver1/2.
#
# License: MIT

set -euo pipefail

# ── Config ──
ROUTER="${ROUTER:-192.168.15.1}"
PASSWORD="${PASSWORD:?Set PASSWORD env var (router admin password from sticker)}"
DNS1="${1:?Usage: update-dns.sh <primary_dns> [secondary_dns]}"
DNS2="${2:-}"
COOKIE_JAR=$(mktemp)
trap 'rm -f "$COOKIE_JAR"' EXIT

BASE="http://$ROUTER"

# ── Step 1: Obtain session cookie ──
echo ">> Obtaining session from $BASE/login.asp ..."
if ! curl -s -c "$COOKIE_JAR" "$BASE/login.asp" > /dev/null; then
  echo "ERROR: Cannot reach $BASE" >&2
  exit 1
fi

# ── Step 2: Authenticate ──
echo ">> Authenticating as admin ..."
AUTH_RESP=$(curl -s -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
  -d "loginUsername=admin&loginPassword=$PASSWORD" \
  "$BASE/cgi-bin/te_acceso_router.cgi")

if echo "$AUTH_RESP" | grep -qi "fail\|error\|denied"; then
  echo "ERROR: Authentication failed. Check PASSWORD." >&2
  echo "       (usually the password on the router's sticker)" >&2
  exit 1
fi

# ── Step 3: Update DNS servers ──
echo ">> Setting DNS1=$DNS1${DNS2:+ DNS2=$DNS2}..."

if [ -n "$DNS2" ]; then
  POST_DATA="Password=$PASSWORD&DNSserver1=$DNS1&DNSserver2=$DNS2"
else
  POST_DATA="Password=$PASSWORD&DNSserver1=$DNS1"
fi

# The /te_red_local.asp page accepts POST with DNS fields.
# This is the same form the Selenium script (rogocal/movistar-router-automatizer)
# interacts with — it sends Password + DNSserver1 + DNSserver2.
UPDATE_RESP=$(curl -s -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
  -d "$POST_DATA" \
  "$BASE/te_red_local.asp")

# ── Verification ──
if echo "$UPDATE_RESP" | grep -qi "error\|fail\|invalid"; then
  echo "WARNING: DNS update may have failed. Response:"
  echo "$UPDATE_RESP" | head -5
  exit 1
fi

echo ">> DNS update submitted successfully."
echo "   Verify at http://$ROUTER/te_red_local.asp (or advanced: $BASE/padrao/)"
echo ""
echo "NOTE: If the router reboots or resets config, re-run this script."
echo "      For persistent changes, consider combining with ASPSH (SSH)."
echo "      See docs/router/askey-rtf8115vw.md for details."
