#!/usr/bin/env bash
# install.sh — Install packages for Raspberry Pi (Pi-hole)
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

install_path="$REPO_DIR/install"

# ── System packages ────────────────────────────────────────────
info "Installing system packages..."
bash "$install_path/ubuntu/bootstrap.sh"

# ── Tailscale ───────────────────────────────────────────────────
info "Installing Tailscale..."
bash "$install_path/_tailscale.sh"
bash "$HOST_DIR/tailscale/start.sh"

# ── Pi-hole ────────────────────────────────────────────────────
info "Installing Pi-hole..."
bash "$install_path/_pihole.sh"

info "Install complete — run configure.sh next"
