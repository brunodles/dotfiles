#!/usr/bin/env bash
# install.sh — Install software for macOS work machine
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

if [[ "$(uname)" != "Darwin" ]]; then
  error "This script is for macOS only."
  exit 1
fi

# ── 1. Xcode Command Line Tools ──────────────────────────────
info "Checking Xcode Command Line Tools..."
if xcode-select -p &>/dev/null; then
  info "  Already installed"
else
  info "  ⚠️  This will open a GUI prompt. Click Install."
  xcode-select --install
  info "  ⏳ Waiting for installation to finish..."
  until xcode-select -p &>/dev/null; do
    sleep 5
  done
  info "  Installed"
fi

# ── 2. Homebrew ──────────────────────────────────────────────
info "Installing Homebrew..."
bash "$REPO_DIR/install/_homebrew.sh"

# ── 3. Oh My Zsh ─────────────────────────────────────────────
info "Installing Oh My Zsh..."
bash "$REPO_DIR/install/_oh-my-zsh.sh"

info "Install complete — run configure.sh and links.sh"
