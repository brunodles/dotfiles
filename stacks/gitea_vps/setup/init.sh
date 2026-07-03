#!/bin/bash
# init.sh — One-time Gitea setup via CLI + API
#
# Designed to run as an init container (compose service gitea-setup).
# Uses gitea CLI for user/token ops and curl for repo/webhook ops.
# Every operation is idempotent — safe to re-run.
set -euo pipefail

# ── Config ──────────────────────────────────────────────────────────────
BASE_URL="http://gitea:3000"
CURL="curl -sS"
TOKEN_FILE="/data/.gitea-hermes-token"
ADMIN_USER="${GITEA_ADMIN_USER:-bruno}"
ADMIN_PASS="${GITEA_ADMIN_PASS:?required}"
ADMIN_EMAIL="${GITEA_ADMIN_EMAIL:-$ADMIN_USER@vps}"
HERMES_PASS="${HERMES_PASS:-changeme-on-first-login}"

# ── Colors ──────────────────────────────────────────────────────────────
info()  { echo "[INFO] $*"; }
warn()  { echo "[WARN] $*" >&2; }

# ── 1. Admin user ───────────────────────────────────────────────────────
if gitea admin user list 2>/dev/null | grep -qi "^$ADMIN_USER$"; then
  info "Admin user '$ADMIN_USER' already exists"
else
  info "Creating admin user '$ADMIN_USER'..."
  gitea admin user create \
    --username "$ADMIN_USER" \
    --password "$ADMIN_PASS" \
    --email "$ADMIN_EMAIL" \
    --admin --must-change-password=false
fi

# ── 2. Hermes user ──────────────────────────────────────────────────────
if gitea admin user list 2>/dev/null | grep -qi "^hermes$"; then
  info "Hermes user already exists"
else
  info "Creating Hermes user..."
  gitea admin user create \
    --username hermes \
    --password "$HERMES_PASS" \
    --email hermes@vps \
    --must-change-password=false
fi

# ── 3. Hermes PAT ───────────────────────────────────────────────────────
if [ -f "$TOKEN_FILE" ] && [ -s "$TOKEN_FILE" ]; then
  info "Hermes PAT already exists at $TOKEN_FILE"
else
  info "Generating Hermes PAT..."
  gitea admin user generate-access-token \
    --username hermes --raw > "$TOKEN_FILE" 2>/dev/null || {
    warn "CLI token generation failed — falling back to API"
    # Fallback: generate via admin auth
    # First get admin session token
    ADMIN_TOKEN=$(curl -sS -X POST "$BASE_URL/api/v1/users/$ADMIN_USER/tokens" \
      -u "$ADMIN_USER:$ADMIN_PASS" \
      -H "Content-Type: application/json" \
      -d '{"name":"admin-init"}' 2>/dev/null | grep -o '"sha1":"[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$ADMIN_TOKEN" ]; then
      curl -sS -X POST "$BASE_URL/api/v1/users/hermes/tokens" \
        -H "Authorization: token $ADMIN_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"name":"hermes-auto","scopes":["write:repository","write:issue","write:user","write:admin"]}' \
        | grep -o '"sha1":"[^"]*"' | cut -d'"' -f4 > "$TOKEN_FILE"
    fi
  }
  chmod 600 "$TOKEN_FILE"
  info "Hermes PAT saved to $TOKEN_FILE"
fi

# Token is needed for API operations below
HERMES_TOKEN="$(cat "$TOKEN_FILE" 2>/dev/null || true)"

# ── 4. Wait for Gitea HTTP (repos/webhooks need running API) ─────────────
if [ -n "$HERMES_TOKEN" ]; then
  info "Waiting for Gitea HTTP..."
  for i in $(seq 1 30); do
    $CURL -o /dev/null "$BASE_URL/" 2>/dev/null && break
    sleep 2
  done
fi

# ── 5. Repos via API ─────────────────────────────────────────────────────
create_repo() {
  local name="$1" desc="$2"
  if $CURL -o /dev/null "$BASE_URL/api/v1/repos/hermes/$name" 2>/dev/null; then
    info "  Repo '$name' already exists"
    return 0
  fi
  info "  Creating repo '$name'..."
  $CURL -X POST "$BASE_URL/api/v1/user/repos" \
    -H "Authorization: token $HERMES_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"$name\",\"auto_init\":true,\"private\":false,\"description\":\"$desc\"}" \
    -o /dev/null && info "  Repo '$name' created" || warn "  Failed to create repo '$name'"
}

if [ -n "$HERMES_TOKEN" ]; then
  info "Creating repos..."
  create_repo "dotfiles" "Bruno's dotfiles — mirrored from GitHub"
  create_repo "hermes-plans" "Plans, PRDs, and task tracking for Hermes agent"
  create_repo "docs" "Docstore — knowledge base served by Jekyll + Calibre"
fi

# ── 6. Docs webhook via API ──────────────────────────────────────────────
if [ -n "${DOCS_WEBHOOK_SECRET:-}" ] && [ -n "$HERMES_TOKEN" ]; then
  info "Creating docs webhook (pointing to docs-sync)..."
  if $CURL -o /dev/null "$BASE_URL/api/v1/repos/hermes/docs/hooks" 2>/dev/null; then
    # Check if webhook already exists
    EXISTING=$($CURL "$BASE_URL/api/v1/repos/hermes/docs/hooks" 2>/dev/null | \
      grep -c '"url":"http://docs-sync:8080/hook' || true)
    if [ "$EXISTING" -gt 0 ]; then
      info "  Docs webhook already exists"
    else
      $CURL -X POST "$BASE_URL/api/v1/repos/hermes/docs/hooks" \
        -H "Authorization: token $HERMES_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"type\":\"gitea\",\"config\":{\"url\":\"http://docs-sync:8080/hook?secret=$DOCS_WEBHOOK_SECRET\",\"content_type\":\"json\"},\"events\":[\"push\"],\"active\":true}" \
        -o /dev/null && info "  Docs webhook created" || warn "  Failed to create webhook"
    fi
  else
    warn "  Could not check existing webhooks — docs repo may not exist yet"
  fi
else
  warn "DOCS_WEBHOOK_SECRET not set — skipping docs webhook"
fi

# ── Done ─────────────────────────────────────────────────────────────────
echo ""
info "═══════════════════════════════════════════════"
info "  Gitea setup complete!"
info "  Admin: $ADMIN_USER / $ADMIN_EMAIL"
info "  Hermes: hermes / hermes@vps"
info "  Token:  $TOKEN_FILE"
info "  Repos:  dotfiles, hermes-plans, docs"
info "  Webhook: ${DOCS_WEBHOOK_SECRET:+✔}${DOCS_WEBHOOK_SECRET:-✘}"
info "═══════════════════════════════════════════════"
