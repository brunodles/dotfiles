#!/usr/bin/env bash
# bootstrap.sh — Setup macOS workstation (work)
#
# Usage:
#   git clone https://github.com/brunodles/dotfiles.git
#   cd dotfiles
#   bash host/work/bootstrap.sh

set -euo pipefail
trap 'echo "❌ Error on line ${LINENO}" >&2' ERR

REPO="$HOME/dotfiles"

if [[ ! -d "$REPO" ]]; then
  echo "Error: dotfiles repo not found at $REPO" >&2
  echo "Clone it first:" >&2
  echo "  git clone https://github.com/brunodles/dotfiles.git ~/dotfiles" >&2
  exit 1
fi

echo "🖥  Work macOS setup"
echo ""

# ── 1. Xcode Command Line Tools ──────────────────────────────
echo "=== Xcode Command Line Tools ==="
if xcode-select -p &>/dev/null; then
  echo "   ✅ Already installed"
else
  echo "   ⚠️  This will open a GUI prompt. Click Install."
  xcode-select --install
  echo "   ⏳ Waiting for installation to finish..."
  until xcode-select -p &>/dev/null; do
    sleep 5
  done
  echo "   ✅ Installed"
fi

# ── 2. Homebrew ──────────────────────────────────────────────
echo ""
echo "=== Homebrew ==="
"$REPO/install/_homebrew.sh"

# ── 3. Oh My Zsh ─────────────────────────────────────────────
echo ""
echo "=== Oh My Zsh ==="
bash "$REPO/install/_oh-my-zsh.sh"

# ── 4. Dotfiles symlinks ─────────────────────────────────────
echo ""
echo "=== Dotfiles ==="
link_script="$REPO/scripts/install/link"
if [[ -x "$link_script" ]]; then
  bash "$link_script"
else
  echo "   ⚠️  scripts/install/link not found — running manual symlinks"
  mkdir -p "$HOME/.config"

  ln -sf "$REPO/dotfiles/.vimrc" "$HOME/.vimrc"
  ln -sf "$REPO/dotfiles/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
  ln -sf "$REPO/dotfiles/zsh" "$HOME/.config/zsh"
  ln -sf "$HOME/.config/zsh/zshrc" "$HOME/.zshrc"
fi

# ── 5. Set default shell ─────────────────────────────────────
echo ""
echo "=== Default shell ==="
if [[ "$SHELL" != "/bin/zsh" ]]; then
  chsh -s /bin/zsh
  echo "   ✅ Default shell set to zsh (log out and back in)"
else
  echo "   ✅ zsh is already the default shell"
fi

# ── Done ─────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Work macOS setup complete"
echo ""
echo "  Next steps:"
echo "   1. Open Ghostty to confirm the terminal config"
echo "   2. Open neovim and run :Lazy sync"
echo "   3. Log out and back in to use zsh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
