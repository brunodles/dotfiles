#!/data/data/com.termux/files/usr/bin/bash
# configure.sh — Configure settings for phone (terminal client)
#
# Run after install.sh:
#   cd ~/dotfiles && bash hosts/phone/bootstrap/configure.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_DIR="$(dirname "$SCRIPT_DIR")"     # hosts/phone
DOTFILES="${DOTFILES:-$HOME/dotfiles}"
SCRIPT_TERMUX="$DOTFILES/scripts/termux"

# ── Colors ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

if [[ ! -d /data/data/com.termux ]]; then
  error "This script must run inside Termux on Android."
  exit 1
fi

# ──────────────────────────────────────────────
# 1. Copy Termux extra-keys config (shared)
# ──────────────────────────────────────────────
info "Configuring Termux extra-keys..."
mkdir -p "$HOME/.termux"
if [[ -f "$SCRIPT_TERMUX/termux.properties" ]]; then
  cp "$SCRIPT_TERMUX/termux.properties" "$HOME/.termux/termux.properties"
  termux-reload-settings 2>/dev/null || true
  info "  termux.properties applied."
fi

# ──────────────────────────────────────────────
# 2. Set Zsh as default shell
# ──────────────────────────────────────────────
if [[ "$SHELL" != */zsh ]]; then
  info "Changing default shell to zsh..."
  ZSH_PATH=$(command -v zsh)
  if [[ -n "$ZSH_PATH" ]]; then
    echo "$ZSH_PATH" > "$HOME/.termux/shell"
    info "  Set default shell to zsh in ~/.termux/shell"
    info "  ➜  Restart Termux or start a new session to apply."
  fi
fi

# ──────────────────────────────────────────────
# 3. Copy shared Termux scripts to ~/.local/bin
# ──────────────────────────────────────────────
info "Installing Termux scripts..."
mkdir -p "$HOME/.local/bin"

if [[ -d "$SCRIPT_TERMUX/bin" ]]; then
  for script in "$SCRIPT_TERMUX/bin/"*; do
    cp "$script" "$HOME/.local/bin/"
  done
  chmod +x "$HOME/.local/bin/"*
  info "  Scripts installed:"
  ls -1 "$HOME/.local/bin/"
fi

# ──────────────────────────────────────────────
# 4. Copy SSH config for homelab hosts
# ──────────────────────────────────────────────
info "Configuring SSH..."
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [[ -f "$HOST_DIR/home/.ssh/config" ]]; then
  cp "$HOST_DIR/home/.ssh/config" "$HOME/.ssh/config"
  chmod 600 "$HOME/.ssh/config"
  info "  SSH config copied."
fi

# ──────────────────────────────────────────────
# 5. Generate SSH key pair (if missing)
# ──────────────────────────────────────────────
if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
  info "Generating SSH key pair..."
  info "You will be prompted for a passphrase (recommended for a mobile device)."
  ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -C "phone-$(date +%Y%m%d)"
  echo ""
  info "📄 Public key — add this to each server's authorized_keys:"
  cat "$HOME/.ssh/id_ed25519.pub"
else
  info "  SSH key already exists, skipping."
fi

# ──────────────────────────────────────────────
# 7. Create workspace directory
# ──────────────────────────────────────────────
mkdir -p "$HOME/workspace"
info "  Workspace: ~/workspace"

# ── Done ──
echo ""
info "═══════════════════════════════════════════"
info "  ✅ Phone configuration complete!"
info "  ➜  Run links.sh to symlink dotfiles"
info "═══════════════════════════════════════════"

# ──────────────────────────────────────────────
# 8. set default shell
# ──────────────────────────────────────────────
chsh -s zsh
