#!/data/data/com.termux/files/usr/bin/bash
# configure.sh — Configure Android/Termux settings
#
# Run after install.sh:
#   cd ~/dotfiles && bash hosts/android/bootstrap/configure.sh

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
source "$HOME/dotfiles/scripts/bootstrap/_env.source.sh"

if [[ ! -d /data/data/com.termux ]]; then
  error "This script must run inside Termux on Android."
  exit 1
fi

link="$SCRIPT_BOOTSTRAP_DIR/link"

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
# 9. SSH authorized keys
# ──────────────────────────────────────────────
info "Setting up SSH authorized_keys..."
AUTH_KEYS="$HOME/.ssh/authorized_keys"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

SSHD_CONFIG="$PREFIX/etc/ssh/sshd_config.d/port.conf"
if [[ ! -f "$SSHD_CONFIG" ]] || ! grep -q "Port 8022" "$SSHD_CONFIG" 2>/dev/null; then
  mkdir -p "$(dirname "$SSHD_CONFIG")"
  echo "Port 8022" > "$SSHD_CONFIG"
  info "  SSH configured on port 8022"
fi

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
# 11. Create ~/workspace directory
# ──────────────────────────────────────────────
mkdir -p "$HOME/workspace"
info "Workspace directory ready at ~/workspace"

# ──────────────────────────────────────────────
# 13. Create convenience aliases
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
# 12. DNS — Unbound (commented: ready for redundant DNS)
# ──────────────────────────────────────────────
# Unbound provides a lightweight DNS forwarder with TLS fallback.
# When Pi-hole is unreachable (power outage), Android resolves via Cloudflare.
# See hosts/android/dns/unbound.conf for the full config.
#
# To enable:
#   pkg install unbound
#   cp "$HOST_DIR/dns/unbound.conf" "$PREFIX/etc/unbound/unbound.conf"
#   mkdir -p "$PREFIX/var/service/unbound/log"
#   # Create sv run script (similar to SSH section)
#   sv-enable unbound
#   sv up unbound
#   # Update router DHCP: Secondary DNS = <android-ip>
#
# To test:
#   dig @localhost google.com              # local resolution
#   dig @<android-ip> google.com           # from another host
#   unbound-control stats                  # cache hit ratio

info "Unbound DNS config ready at $HOST_DIR/dns/unbound.conf"
info "  Enable manually with 'pkg install unbound && sv-enable unbound'"

# ── Done ──
echo ""
info "═══════════════════════════════════════════"
info "  ✅ Android configure complete!"
info "  ➜  Run links.sh to symlink dotfiles"
info "═══════════════════════════════════════════"
echo ""
