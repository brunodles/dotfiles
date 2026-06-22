#!/data/data/com.termux/files/usr/bin/bash
# _lib.sh — Shared functions for Android Termux bootstrap
#
# Source this file from install.sh, configure.sh, and links.sh:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/_lib.sh"

set -euo pipefail

# ── Colors ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ── Logging ──
info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ── Derived paths ──
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_DIR="$(dirname "$SCRIPT_DIR")"  # hosts/android
REPO_DIR="$(cd "$HOST_DIR/.." && pwd)"  # dotfiles root (parent of hosts/)
DOTFILES="${DOTFILES:-$HOME/dotfiles}"
