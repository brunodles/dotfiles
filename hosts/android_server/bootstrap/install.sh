#!/data/data/com.termux/files/usr/bin/bash
# install.sh — Install packages and tools for Android/Termux
#
# Run once per device (idempotent):
#   cd ~/dotfiles && bash hosts/android/bootstrap/install.sh

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
source "$HOME/dotfiles/scripts/bootstrap/_env.source.sh"

# ── Sanity checks ──
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
  make \
  man \
  which \
  yq

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
# 8. Set up SSH server via termux-services
# ──────────────────────────────────────────────
info "Configuring SSH server..."

if [[ ! -f "$PREFIX/etc/ssh/ssh_host_ed25519_key" ]]; then
  ssh-keygen -A
fi

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

sv-enable sshd 2>/dev/null || true
sv up sshd 2>/dev/null || true

# ──────────────────────────────────────────────
# 9. Set up Dnsmasq DNS forwarder
# ──────────────────────────────────────────────
info "Configuring Dnsmasq DNS forwarder..."

# Ensure dnsmasq binary is available
if ! command -v dnsmasq &>/dev/null; then
  info "  dnsmasq not found, trying package install..."
  if ! pkg install -y dnsmasq 2>/dev/null; then
    info "  Not in Termux repos, building from source..."
    DNSMASQ_VERSION="2.93"
    BUILDDIR=$(mktemp -d)
    cd "$BUILDDIR"
    if curl -sL "https://thekelleys.org.uk/dnsmasq/dnsmasq-${DNSMASQ_VERSION}.tar.gz" | tar xz; then
      cd "dnsmasq-${DNSMASQ_VERSION}"
      NPROC=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)
      make -j "$NPROC" CC=clang 2>&1 || make CC=clang 2>&1
      cp src/dnsmasq "$PREFIX/bin/dnsmasq"
      chmod +x "$PREFIX/bin/dnsmasq"
      rm -rf "$BUILDDIR"
      ok "  dnsmasq ${DNSMASQ_VERSION} built and installed from source"
    else
      rm -rf "$BUILDDIR"
      warn "  Failed to download dnsmasq source"
      warn "  DNS forwarder will not be available until dnsmasq is manually installed"
    fi
  fi
fi

SVDIR="$PREFIX/var/service"
if [[ -d "$SVDIR/dnsmasq" ]]; then
  info "  Dnsmasq service directory already exists at $SVDIR/dnsmasq"
else
  info "  Creating Dnsmasq service directory..."
  mkdir -p "$SVDIR/dnsmasq/log"
  cat > "$SVDIR/dnsmasq/run" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
exec dnsmasq -k 2>&1
EOF
  chmod +x "$SVDIR/dnsmasq/run"

  cat > "$SVDIR/dnsmasq/log/run" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
exec svlogd -tt "$PREFIX/var/log/dnsmasq"
EOF
  chmod +x "$SVDIR/dnsmasq/log/run"
fi

sv-enable dnsmasq 2>/dev/null || true
sv up dnsmasq 2>/dev/null || true

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

# ── Done ──
echo ""
info "═══════════════════════════════════════════"
info "  ✅ Android install complete!"
info "  ➜  Run configure.sh to configure settings"
info "  ➜  Run links.sh to symlink dotfiles"
info "═══════════════════════════════════════════"
echo ""
