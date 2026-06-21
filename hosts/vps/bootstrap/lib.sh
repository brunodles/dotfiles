#!/usr/bin/env bash
# lib.sh — Shared functions for VPS bootstrap
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_DIR="$(dirname "$SCRIPT_DIR")"
REPO_DIR="$(cd "$HOST_DIR/.." && pwd)"

info()  { echo -e "\033[0;32m[INFO]\033[0m $*"; }
warn()  { echo -e "\033[1;33m[WARN]\033[0m $*"; }
error() { echo -e "\033[0;31m[ERROR]\033[0m $*" >&2; }
