#!/usr/bin/env bash
# configure.sh — Configure macOS work machine
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# ── 5. Set default shell ─────────────────────────────────────
info "Setting default shell to zsh..."
if [[ "$SHELL" != "/bin/zsh" ]]; then
  chsh -s /bin/zsh
  info "  Default shell set to zsh (log out and back in)"
else
  info "  zsh is already the default shell"
fi

info "Configure complete — run links.sh"
