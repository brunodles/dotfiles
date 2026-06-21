#!/usr/bin/env bash
# install.sh — Install software for media server
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

install_path="$REPO_DIR/install"
install_ubuntu="$install_path/ubuntu"

info "Running Ubuntu bootstrap..."
"$install_ubuntu/bootstrap.sh"

info "Setting up Docker..."
"$install_ubuntu/docker.sh"

info "Running shared installers..."
bash "$install_path/_oh-my-zsh.sh"
bash "$install_path/_tmux.post-install.sh"
bash "$install_path/_samba.post-install.sh"

info "Media install complete — run configure.sh next"
