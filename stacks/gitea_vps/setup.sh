#!/usr/bin/env bash
# setup.sh — [DEPRECATED] Bootstrap Gitea on VPS
#
# This script is deprecated. The gitea-setup init container now handles
# all setup automatically via stacks/gitea_vps/setup/init.sh.
# See compose.yml for the gitea-setup service definition.
#
# Kept for reference and manual fallback. To re-run setup:
#   1. docker compose rm -f gitea-setup
#   2. rm /opt/dockge_data/gitea_vps/data/.gitea-hermes-token
#   3. docker compose up -d
#

# ── Guard: must NOT run as root ─────────────────────────────────────────
if [[ $EUID -eq 0 ]]; then
  echo -e "\033[0;31m\u2717 Do not run setup.sh as root.\033[0m" >&2
  echo "  Run as a normal user with Docker access (e.g. via the docker group)." >&2
  exit 1
fi

# ── Paths ──────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE="docker compose -f $SCRIPT_DIR/compose.yml"
GITEA="$COMPOSE exec --user git -T gitea gitea"
BASE_URL="http://gitea:3000"

# DOCKGE_DATA_DIR vem do .env do stack (ou da Dockge env)
DOCKGE_DATA="${DOCKGE_DATA_DIR:-/opt/dockge_data}"
HERMES_DATA_DIR="$DOCKGE_DATA/hermes"
HERMES_TOKEN_FILE="$HERMES_DATA_DIR/.gitea-token"

# ── Colors ──────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}\u2022${NC} $*"; }
warn()  { echo -e "${YELLOW}\u26a0 $*${NC}" >&2; }
err()   { echo -e "${RED}\u2717 $*${NC}" >&2; }

# ── Arg parse ───────────────────────────────────────────────────────────
ADMIN_USER=""; ADMIN_PASS=""; ADMIN_EMAIL=""; HERMES_TOKEN=""
NON_INTERACTIVE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --admin-user)    ADMIN_USER="$2";  shift 2 ;;
    --admin-pass)    ADMIN_PASS="$2";  shift 2 ;;
    --admin-email)   ADMIN_EMAIL="$2"; shift 2 ;;
    --hermes-token)  HERMES_TOKEN="$2"; shift 2 ;;
    --non-interactive) NON_INTERACTIVE=true; shift ;;
    -h|--help)
      cat <<'HELP'
Usage: bash setup.sh [options]

Options:
  --admin-user <u>     Admin username
  --admin-pass <p>     Admin password
  --admin-email <e>    Admin email
  --hermes-token <t>   Pre-generated PAT for Hermes user
  --non-interactive    Skip all prompts (requires --admin-* flags)
  -h, --help           Show this help
HELP
      exit 0 ;;
    *) err "Unknown: $1"; exit 1 ;;
  esac
done

# ── Helpers ──────────────────────────────────────────────────────────────

prompt() {
  local var="$1" label="$2" default="$3" hidden="${4:-}"
  local val
  while true; do
    if [[ "$hidden" == "hidden" ]]; then
      read -r -s -p "$label: " val; echo >&2
      [[ -z "$val" && -n "$default" ]] && val="$default"
      [[ -z "$val" ]] && { err "Password cannot be empty"; continue; }
      read -r -s -p "Confirm: " confirm; echo >&2
      [[ "$val" != "$confirm" ]] && { err "Passwords don't match"; continue; }
    else
      read -r -p "$label: " val
      [[ -z "$val" && -n "$default" ]] && val="$default"
      [[ -z "$val" && -z "$default" ]] && { err "Required"; continue; }
    fi
    break
  done
  eval "$var=\"$val\""
}

wait_healthy() {
  info "Waiting for Gitea to be healthy..."
  for i in $(seq 1 30); do
    if $COMPOSE exec -T gitea curl -sf -o /dev/null http://localhost:3000/ 2>/dev/null; then
      info "Gitea is responding"
      return 0
    fi
    sleep 2
  done
  err "Gitea didn't become healthy within 60s"
  exit 1
}

user_exists() {
  local username="$1"
  $GITEA admin user list 2>/dev/null | grep -qi "^$username$"
}

api_call() {
  local method="$1" path="$2" token="$3" body="${4:-}"
  local args=(-sS -X "$method" "$BASE_URL$path")
  [[ -n "$token" ]] && args+=(-H "Authorization: token $token")
  args+=(-H "Content-Type: application/json" -H "Accept: application/json")
  [[ -n "$body" ]] && args+=(-d "$body")
  curl "${args[@]}"
}

# ── 1. Ensure stack is running ──────────────────────────────────────────

info "Checking Gitea stack..."
if ! $COMPOSE ps --status running 2>/dev/null | grep -q "gitea.*Up"; then
  $COMPOSE up -d
  info "Stack started"
else
  info "Stack already running"
fi

wait_healthy

# ── 2. Admin user ────────────────────────────────────────────────────────

if $NON_INTERACTIVE; then
  [[ -z "$ADMIN_USER" || -z "$ADMIN_PASS" ]] && {
    err "--non-interactive requires --admin-user and --admin-pass"
    exit 1
  }
  ADMIN_EMAIL="${ADMIN_EMAIL:-$ADMIN_USER@lab}"
else
  prompt ADMIN_USER  "Admin username" "bruno"
  prompt ADMIN_EMAIL "Admin email"    "bruno@lab"
  prompt ADMIN_PASS  "Admin password" "" "hidden"
fi

if user_exists "$ADMIN_USER"; then
  warn "Admin user '$ADMIN_USER' already exists — skipping"
else
  info "Creating admin user '$ADMIN_USER'..."
  $GITEA admin user create \
    --username "$ADMIN_USER" \
    --password "$ADMIN_PASS" \
    --email "$ADMIN_EMAIL" \
    --admin --must-change-password=false
  info "Admin user created"
fi

# ── 3. Hermes user ────────────────────────────────────────────────────────

if user_exists "hermes"; then
  warn "Hermes user already exists — skipping"
else
  info "Creating Hermes user..."
  $GITEA admin user create \
    --username hermes \
    --password "changeme-on-first-login" \
    --email hermes@vps \
    --must-change-password=false
  info "Hermes user created"
fi

# ── 4. Hermes PAT ─────────────────────────────────────────────────────────

if [[ -z "$HERMES_TOKEN" ]]; then
  # Try CLI token generation (v1.21+)
  HERMES_TOKEN=$(
    $GITEA admin user generate-access-token \
      --username hermes --raw 2>/dev/null || true
  )

  # CLI failed — fallback to API
  if [[ -z "$HERMES_TOKEN" ]]; then
    warn "Falling back to API token generation..."
    HERMES_TOKEN=$(
      api_call POST "/api/v1/users/hermes/tokens" "" \
        '{"name":"hermes-auto","scopes":["write:repository","write:issue","write:user","write:admin"]}' \
      2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('sha1', ''))
except Exception:
    print('')
" || true
    )
  fi
fi

if [[ -z "$HERMES_TOKEN" ]]; then
  warn "Could not generate Hermes PAT — create one manually at /user/settings/applications"
else
  if [[ -d "$HERMES_DATA_DIR" ]]; then
    echo "$HERMES_TOKEN" > "$HERMES_TOKEN_FILE"
    chmod 600 "$HERMES_TOKEN_FILE"
    info "Hermes token saved to $HERMES_TOKEN_FILE"
  else
    info "Hermes PAT: $HERMES_TOKEN"
  fi
fi

# ── 5. Repositories ──────────────────────────────────────────────────────

create_repo() {
  local name="$1" desc="$2"
  local resp
  resp=$(api_call GET "/api/v1/repos/hermes/$name" "$HERMES_TOKEN" 2>/dev/null)
  if echo "$resp" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    sys.exit(0 if d.get('name') else 1)
except Exception:
    sys.exit(1)
" 2>/dev/null; then
    warn "Repo '$name' already exists — skipping"
    return 0
  fi

  info "Creating repo '$name'..."
  resp=$(api_call POST "/api/v1/user/repos" "$HERMES_TOKEN" \
    "{\"name\":\"$name\",\"auto_init\":true,\"private\":false,\"description\":\"$desc\"}" 2>/dev/null) || {
    err "Failed to create '$name'"
    return 1
  }
  info "Repo '$name' created"
}

create_repo "dotfiles" "Bruno's dotfiles — mirrored from GitHub"
create_repo "hermes-plans" "Plans, PRDs, and task tracking for Hermes agent"
create_repo "docs" "Docstore — knowledge base served by Jekyll + Calibre"

# ── 7. Docs webhook ──────────────────────────────────────────────────

WEBHOOK_SECRET="${DOCS_WEBHOOK_SECRET:-}"
if [[ -n "$WEBHOOK_SECRET" && -n "$HERMES_TOKEN" ]]; then
  info "Creating docs webhook (pointing to docs-sync)..."
  _resp=$(api_call POST "/api/v1/repos/hermes/docs/hooks" "$HERMES_TOKEN" \
    "$(cat <<JSON
{
  "type": "gitea",
  "config": {
    "url": "http://docs-sync:8080/hook?secret=$WEBHOOK_SECRET",
    "content_type": "json"
  },
  "events": ["push"],
  "active": true
}
JSON
  )")
  _webhook_id=$(echo "$_resp" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('id', ''))
except Exception:
    print('')
" 2>/dev/null)
  if [[ -n "$_webhook_id" ]]; then
    info "  docs webhook created (id: $_webhook_id)"
  else
    warn "  failed to create webhook"
  fi
else
  warn "WEBHOOK_SECRET not set — skipping docs webhook (create manually in Gitea UI)"
fi

# ── 8. Summary ───────────────────────────────────────────────────────────

echo ""
echo "═══════════════════════════════════════════════════"
echo "  Gitea setup complete!"
echo ""
echo "  Admin: $ADMIN_USER / $ADMIN_EMAIL"
echo "  Hermes: hermes / hermes@vps"
echo "  Token:  ${HERMES_TOKEN:+$HERMES_TOKEN_FILE}"
echo "  Repos:  dotfiles, hermes-plans, docs"
echo "  Webhook: docs → docs-sync ${DOCS_WEBHOOK_SECRET:+✔}${DOCS_WEBHOOK_SECRET:-✘}"
echo ""
echo "  Access: http://gitea.lab  (Traefik)"
echo "          http://gitea:3000  (Docker internal)"
echo ""
echo "  Next:"
echo "    Deploy docs stack: cd stacks/docs && docker compose up -d"
echo "    Clone locally:     git clone http://gitea:3000/hermes/dotfiles.git"
echo "═══════════════════════════════════════════════════"
