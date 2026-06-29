#!/data/data/com.termux/files/usr/bin/bash
# links.sh — Symlink dotfiles for Android/Termux
#
# Run after install.sh and configure.sh:
#   cd ~/dotfiles && bash hosts/android/bootstrap/links.sh

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

if [[ ! -d /data/data/com.termux ]]; then
  error "This script must run inside Termux on Android."
  exit 1
fi

link="$REPO_DIR/scripts/install/link"
home_config="$HOME/.config"
repo_config="$REPO_DIR/dotfiles"

mkdir -p "$home_config"

# ──────────────────────────────────────────────
# 4. Link dotfiles
# ──────────────────────────────────────────────
info "Linking dotfiles..."

bash "$link" "$repo_config/.vimrc" "$HOME/.vimrc"
bash "$link" "$repo_config/tmux/tmux.conf" "$home_config/tmux/tmux.conf"
bash "$link" "$repo_config/zsh" "$home_config/zsh"
bash "$link" "$home_config/zsh/zshrc" "$HOME/.zshrc"

# ──────────────────────────────────────────────
# 8. Link runit services
# ──────────────────────────────────────────────
SVDIR="$PREFIX/var/service"
REPO_SVDIR="$REPO_DIR/hosts/android/var/service"

if [[ -d "$REPO_SVDIR/ttsd" ]]; then
  info "Linking ttsd service..."
  mkdir -p "$SVDIR"
  bash "$link" "$REPO_SVDIR/ttsd" "$SVDIR/ttsd"

  if command -v sv-enable &>/dev/null; then
    sv-enable ttsd 2>/dev/null || true
    sv up ttsd 2>/dev/null || true
  fi
fi

# ── Done ──
echo ""
info "═══════════════════════════════════════════"
info "  ✅ Android links complete!"
info "  ➜  Restart Termux or run 'zsh' to switch shell."
info "═══════════════════════════════════════════"
echo ""
