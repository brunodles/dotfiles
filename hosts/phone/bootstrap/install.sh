#!/data/data/com.termux/files/usr/bin/bash
# install.sh — Install packages for phone (terminal client)
#
# Run once per device (idempotent):
#   cd ~/dotfiles && bash hosts/phone/bootstrap/install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="${DOTFILES:-$HOME/dotfiles}"

# ── Colors ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ── Sanity check ──
if [[ ! -d /data/data/com.termux ]]; then
  error "This script must run inside Termux on Android."
  exit 1
fi

# ──────────────────────────────────────────────
# 1. Update packages
# ──────────────────────────────────────────────
info "Updating package list..."
pkg update -y

info "Upgrading packages..."
pkg upgrade -y

# ──────────────────────────────────────────────
# 2. Install packages (terminal client focused)
# ──────────────────────────────────────────────
info "Installing packages..."
pkg install -y \
  zsh \
  git \
  curl \
  openssh \
  neovim \
  tmux \
  termux-api \
  ripgrep \
  fzf \
  man \
  which \
  openssl-tool

# ──────────────────────────────────────────────
# 3. Oh My Zsh + plugins
# ──────────────────────────────────────────────
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  info "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  info "Oh My Zsh already installed, skipping."
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
  info "Installing zsh-autosuggestions..."
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/fast-syntax-highlighting" ]]; then
  info "Installing fast-syntax-highlighting..."
  git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"
fi

# ── Done ──
echo ""
info "═══════════════════════════════════════════"
info "  ✅ Packages installed!"
info "  ➜  Run configure.sh to configure settings"
info "  ➜  Run links.sh to symlink dotfiles"
info "═══════════════════════════════════════════"
