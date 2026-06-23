#!/usr/bin/env bash
# jekyll-sync.sh — Sync Jekyll site source from git
#
# Pulls (or clones) the site content repo into the Jekyll stack's site/
# directory. The jekyll container watches this dir via --watch and
# rebuilds automatically on file changes.
#
# Usage:
#   GIT_REPO=git@github.com:user/blog.git bash scripts/jekyll-sync.sh
#
# Environment:
#   GIT_REPO     Git URL to clone/pull from (required)
#   SITE_DIR     Target directory (default: auto-detect)
#   BRANCH       Git branch to checkout (default: main)
#
# Examples:
#   GIT_REPO=git@github.com:brunodles/blog.git bash scripts/jekyll-sync.sh
#   GIT_REPO=https://github.com/brunodles/blog.git BRANCH=gh-pages bash scripts/jekyll-sync.sh

set -euo pipefail

# ── Config ───────────────────────────────────────────────────
BRANCH="${BRANCH:-main}"

# Auto-detect SITE_DIR if not set
if [[ -z "${SITE_DIR:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

  if [[ -d "$REPO_ROOT/stacks/jekyll/site" ]]; then
    SITE_DIR="$REPO_ROOT/stacks/jekyll/site"
  elif [[ -d "/dockge/stacks/jekyll/site" ]]; then
    SITE_DIR="/dockge/stacks/jekyll/site"
  else
    echo "Error: cannot detect SITE_DIR. Set it explicitly or ensure" >&2
    echo "  stacks/jekyll/site/ exists in the repo or /dockge/stacks/jekyll/site/ on disk." >&2
    exit 1
  fi
fi

# ── Pre-flight ───────────────────────────────────────────────
if [[ -z "${GIT_REPO:-}" ]]; then
  echo "Error: GIT_REPO is not set." >&2
  echo "Usage: GIT_REPO=<url> bash $0" >&2
  exit 1
fi

if ! command -v git &>/dev/null; then
  echo "Error: git is not installed." >&2
  exit 1
fi

# ── Sync ─────────────────────────────────────────────────────
mkdir -p "$SITE_DIR"

if [[ ! -d "$SITE_DIR/.git" ]]; then
  # Empty or non-repo directory — clone
  echo "Cloning $GIT_REPO into $SITE_DIR (branch: $BRANCH)..."
  git clone --branch "$BRANCH" --single-branch "$GIT_REPO" "$SITE_DIR" 2>&1
  echo "✅ Clone complete — $(wc -c < "$SITE_DIR/_config.yml" 2>/dev/null || echo 0) files synced"
elif [[ -d "$SITE_DIR/.git" ]]; then
  # Already a git repo — pull
  echo "Pulling latest into $SITE_DIR (branch: $BRANCH)..."
  git -C "$SITE_DIR" pull origin "$BRANCH" 2>&1
  echo "✅ Pull complete"
else
  echo "Error: $SITE_DIR exists but is not a git repository." >&2
  exit 1
fi
