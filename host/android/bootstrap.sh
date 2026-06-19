#!/data/data/com.termux/files/usr/bin/bash
# bootstrap.sh — Setup Android/Termux device for homelab
#
# Usage:
#   cd ~/dotfiles && bash host/android/bootstrap.sh
#
# This script must run INSIDE Termux on the Android device.

set -euo pipefail
trap 'echo "❌ Error on line ${LINENO}" >&2' ERR

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ──────────────────────────────────────────────
# 0. Sanity checks
# ──────────────────────────────────────────────
if [[ ! -d /data/data/com.termux ]]; then
  error "This script must run inside Termux on Android."
  exit 1
fi

DOTFILES="$HOME/dotfiles"
if [[ ! -d "$DOTFILES" ]]; then
  error "Clone the repo first:"
  error "  pkg install git && git clone https://github.com/brunodles/dotfiles.git"
  exit 1
fi

HOST_DIR="$DOTFILES/host/android"

# ──────────────────────────────────────────────
# 1. Update packages
# ──────────────────────────────────────────────
info "Updating package list..."
pkg update -y

info "Upgrading packages..."
pkg upgrade -y

# ──────────────────────────────────────────────
# 2. Install base packages
# ──────────────────────────────────────────────
info "Installing base packages..."
pkg install -y \
  zsh \
  git \
  curl \
  wget \
  openssh \
  neovim \
  python \
  nodejs \
  tmux \
  termux-services \
  termux-api \
  openssl-tool \
  ripgrep \
  fzf \
  man \
  which

# ──────────────────────────────────────────────
# 3. Oh My Zsh + plugins + theme
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

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]]; then
  info "Installing zsh-completions..."
  git clone https://github.com/zsh-users/zsh-completions.git "$ZSH_CUSTOM/plugins/zsh-completions"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/fast-syntax-highlighting" ]]; then
  info "Installing fast-syntax-highlighting..."
  git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"
fi

if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
  info "Installing Powerlevel10k theme..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
fi

# ──────────────────────────────────────────────
# 4. Link dotfiles
# ──────────────────────────────────────────────
info "Linking dotfiles..."
link="$DOTFILES/scripts/install/link"
home_config="$HOME/.config"
repo_config="$DOTFILES/dotfiles"

mkdir -p "$home_config"

bash "$link" "$repo_config/.vimrc" "$HOME/.vimrc"
bash "$link" "$repo_config/tmux/tmux.conf" "$home_config/tmux/tmux.conf"
bash "$link" "$repo_config/zsh" "$home_config/zsh"
bash "$link" "$home_config/zsh/zshrc" "$HOME/.zshrc"

# ──────────────────────────────────────────────
# 5. Copy Termux extra-keys config
# ──────────────────────────────────────────────
info "Configuring Termux extra-keys..."
mkdir -p "$HOME/.termux"
if [[ -f "$HOST_DIR/termux/termux.properties" ]]; then
  bash "$link" "$HOST_DIR/termux/termux.properties" "$HOME/.termux/termux.properties"
  termux-reload-settings 2>/dev/null || true
fi

# ──────────────────────────────────────────────
# 6. Set Zsh as default shell (Termux-specific)
# ──────────────────────────────────────────────
if [[ "$SHELL" != */zsh ]]; then
  info "Changing default shell to zsh..."
  # Termux reads ~/.termux/shell to determine the login shell
  ZSH_PATH=$(command -v zsh)
  if [[ -n "$ZSH_PATH" ]]; then
    mkdir -p "$HOME/.termux"
    echo "$ZSH_PATH" > "$HOME/.termux/shell"
    info "  Set default shell to zsh in ~/.termux/shell"
    info "  ➜  Restart Termux or start a new session to apply."
  fi
fi

# ──────────────────────────────────────────────
# 7. Copy custom scripts to ~/.local/bin
# ──────────────────────────────────────────────
info "Copying Termux scripts..."
mkdir -p "$HOME/.local/bin"

if [[ -d "$HOST_DIR/home/.local/bin" ]]; then
  cp -r "$HOST_DIR/home/.local/bin/"* "$HOME/.local/bin/"
  chmod +x "$HOME/.local/bin/"*
  info "  Scripts installed:"
  ls -1 "$HOME/.local/bin/"
fi

# ──────────────────────────────────────────────
# 8. Set up SSH server via termux-services
# ──────────────────────────────────────────────
info "Configuring SSH server..."

# Generate host keys if missing
if [[ ! -f "$PREFIX/etc/ssh/ssh_host_ed25519_key" ]]; then
  ssh-keygen -A
fi

# Enable and start sshd via termux-services (sv)
SVDIR="$PREFIX/var/service"
if [[ -d "$SVDIR/sshd" ]]; then
  info "  SSH service directory already exists at $SVDIR/sshd"
else
  info "  Creating SSH service directory..."
  mkdir -p "$SVDIR/sshd"
  cat > "$SVDIR/sshd/run" << 'EOSERVICE'
#!/data/data/com.termux/files/usr/bin/bash
exec sshd -D -p 8022 2>&1
EOSERVICE
  chmod +x "$SVDIR/sshd/run"
fi

# Enable service (starts automatically on boot via termux-services)
sv-enable sshd 2>/dev/null || true
sv up sshd 2>/dev/null || true

# ──────────────────────────────────────────────
# 9. SSH authorized keys (WARNING: placeholder)
# ──────────────────────────────────────────────
info "Setting up SSH authorized_keys..."
AUTH_KEYS="$HOME/.ssh/authorized_keys"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Set SSH port config
SSHD_CONFIG="$PREFIX/etc/ssh/sshd_config.d/port.conf"
if [[ ! -f "$SSHD_CONFIG" ]] || ! grep -q "Port 8022" "$SSHD_CONFIG" 2>/dev/null; then
  mkdir -p "$(dirname "$SSHD_CONFIG")"
  echo "Port 8022" > "$SSHD_CONFIG"
  info "  SSH configured on port 8022"
fi

# If there's a key file in the repo, copy it
if [[ -f "$HOST_DIR/ssh/authorized_keys" ]]; then
  cp "$HOST_DIR/ssh/authorized_keys" "$AUTH_KEYS"
  info "  Copied authorized_keys from repo."
elif [[ ! -f "$AUTH_KEYS" ]]; then
  warn "  No authorized_keys found. Add your public key manually:"
  warn "    echo 'ssh-ed25519 AAAA...' >> ~/.ssh/authorized_keys"
else
  info "  authorized_keys already exists."
fi
chmod 600 "$AUTH_KEYS" 2>/dev/null || true

# ──────────────────────────────────────────────
# 10. Generate SSH key pair (if missing)
# ──────────────────────────────────────────────
if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
  info "Generating SSH key pair..."
  ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N "" -C "termux-$(uname -n)-$(date +%Y%m%d)"
  echo ""
  info "📄 Public key — add this to your homelab gateway authorized_keys:"
  cat "$HOME/.ssh/id_ed25519.pub"
fi

# ──────────────────────────────────────────────
# 11. Create ~/workspace directory
# ──────────────────────────────────────────────
mkdir -p "$HOME/workspace"
info "Workspace directory ready at ~/workspace"

# ──────────────────────────────────────────────
# 12. Create convenience aliases
# ──────────────────────────────────────────────
if ! grep -q "source.*alias" "$HOME/.zshrc" 2>/dev/null; then
  cat >> "$HOME/.zshrc" << 'EOF'

# ── Termux homelab aliases ──
alias wake='termux-wake'
alias sleep='termux-sleep'
alias notify='termux-notify'
alias battery='termux-battery-status'
alias myip='termux-ip'
alias tunnel='termux-ssh-tunnel'
alias svstart='sv up'
alias svstop='sv down'
alias svstatus='sv status'
EOF
  info "Termux aliases added to ~/.zshrc"
fi

# ──────────────────────────────────────────────
# Done!
# ──────────────────────────────────────────────
echo ""
info "═══════════════════════════════════════════"
info "  ✅ Android/Termux setup complete!"
info "═══════════════════════════════════════════"
echo ""
info "  ➜  SSH server running on port 8022"
info "  ➜  Scripts installed at ~/.local/bin/"
info "  ➜  Zsh + Oh My Zsh + Powerlevel10k ready"
info "  ➜  Wakelock:   termux-wake"
info "  ➜  Notify:     termux-notify -t title -c body"
info "  ➜  Tunnel:     termux-ssh-tunnel --host GATEWAY"
info "  ➜  Battery:    termux-battery-status"
info ""
info "  📌  Reboot Termux or run 'zsh' to switch shell."
echo ""
