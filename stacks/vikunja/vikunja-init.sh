#!/bin/sh
# vikunja-init.sh — Entrypoint wrapper for Vikunja
#
# One-time setup (flag file):
#   1. Run DB migration (creates schema if needed)
#   2. Create admin user (idempotent)
#   3. Start Vikunja normally
set -eu

SETUP_FLAG="/data/.setup-complete"

if [ ! -f "$SETUP_FLAG" ]; then
  echo "[init] Running DB migration..."
  /app/vikunja/vikunja migrate 2>&1 | grep -v "already up to date"

  echo "[init] Creating admin user..."
  /app/vikunja/vikunja user create \
    --email "$VIKUNJA_ADMIN_EMAIL" \
    --password "$VIKUNJA_ADMIN_PASS" \
    --username "$VIKUNJA_ADMIN_USER" \
    --admin 2>&1 || echo "[init] Admin user already exists"

  touch "$SETUP_FLAG"
  echo "[init] Setup complete"
fi

echo "[init] Starting Vikunja..."
exec /app/vikunja/vikunja
