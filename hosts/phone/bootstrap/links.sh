#!/data/data/com.termux/files/usr/bin/bash
# links.sh — Symlink dotfiles for phone (terminal client)
#
# Run after install.sh and configure.sh:
#   cd ~/dotfiles && bash hosts/phone/bootstrap/links.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_DIR="$(dirname "$SCRIPT_DIR")"     # hosts/phone
DOTFILES="${DOTFILES:-$HOME/dotfiles}"
SCRIPT_BOOTSTRAP="$DOTFILES/scripts/bootstrap"
link="$SCRIPT_BOOTSTRAP/link"

# ── Colors ──
GREEN='\033[0;32m'
NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC} $*"; }

home_config="$HOME/.config"

mkdir -p "$home_config"

# ──────────────────────────────────────────────
# Link dotfiles
# ──────────────────────────────────────────────
info "Linking dotfiles..."

if [[ -f "$SCRIPT_BOOTSTRAP/link" ]]; then
  bash "$link" "$DOTFILES/.vimrc" "$HOME/.vimrc"
  bash "$link" "$DOTFILES/tmux/tmux.conf" "$home_config/tmux/tmux.conf"
  bash "$link" "$DOTFILES/zsh" "$home_config/zsh"
  bash "$link" "$home_config/zsh/zshrc" "$HOME/.zshrc"
  info "  Dotfiles linked."
else
  # Fallback: direct symlinks if bootstrap/link not available
  mkdir -p "$home_config/tmux" "$home_config/zsh"
  ln -sf "$DOTFILES/.vimrc" "$HOME/.vimrc" 2>/dev/null || true
  ln -sf "$DOTFILES/tmux/tmux.conf" "$home_config/tmux/tmux.conf" 2>/dev/null || true
  ln -sf "$DOTFILES/zsh" "$home_config/zsh" 2>/dev/null || true
  ln -sf "$home_config/zsh/zshrc" "$HOME/.zshrc" 2>/dev/null || true
  info "  Dotfiles linked (direct)."
fi

# ── Done ──
echo ""
info "═══════════════════════════════════════════"
info "  ✅ Phone bootstrap complete!"
info "  ➜  Restart Termux or run 'zsh'"
info "═══════════════════════════════════════════"
