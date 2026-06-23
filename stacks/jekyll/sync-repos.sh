#!/usr/bin/env bash
# sync-repos.sh — Clone/pull content repos into Jekyll site/
#
# Reads repos.txt (one git URL per line), clones or pulls each into
# site/<repo-name>/. The Jekyll container watches site/ via --watch
# and rebuilds automatically.
#
# Intended to run from a system cron job on the VPS.
#
# Usage:
#   bash stacks/jekyll/sync-repos.sh
#
# Environment:
#   SITE_DIR    Target directory (default: auto-detect from script location)

set -euo pipefail

# ── Config ───────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SITE_DIR="${SITE_DIR:-$SCRIPT_DIR/site}"
REPOS_FILE="${REPOS_FILE:-$SCRIPT_DIR/repos.txt}"

# ── Pre-flight ───────────────────────────────────────────────
if [[ ! -f "$REPOS_FILE" ]]; then
  echo "Error: repos.txt not found at $REPOS_FILE" >&2
  echo "Create it with one git URL per line." >&2
  exit 1
fi

if ! command -v git &>/dev/null; then
  echo "Error: git is not installed." >&2
  exit 1
fi

mkdir -p "$SITE_DIR"

# ── Sync ─────────────────────────────────────────────────────
synced=0
skipped=0

while IFS= read -r line || [[ -n "$line" ]]; do
  # Trim whitespace
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"

  # Skip blanks and comments
  [[ -z "$line" || "$line" == \#* ]] && continue

  # Extract repo name from URL (last path component, strip .git)
  repo_name="$(basename "$line" .git)"
  target="$SITE_DIR/$repo_name"

  if [[ -d "$target/.git" ]]; then
    echo "  ↻ $repo_name — pulling..."
    git -C "$target" pull --ff-only --quiet 2>&1 | sed 's/^/    /'
    echo "  ✓ $repo_name — up to date"
  elif [[ -d "$target" ]] && [[ ! -d "$target/.git" ]]; then
    echo "  ⚠ $repo_name — exists but not a git repo, skipping" >&2
    ((skipped++)) || true
  else
    echo "  + $repo_name — cloning..."
    git clone --quiet "$line" "$target" 2>&1 | sed 's/^/    /'
    echo "  ✓ $repo_name — cloned"
    ((synced++)) || true
  fi
done < "$REPOS_FILE"

echo ""
echo "━━━ Done — ${synced} new, $(git rev-list --count HEAD 2>/dev/null || echo '?') total repos"
