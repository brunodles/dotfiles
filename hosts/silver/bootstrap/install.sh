#!/usr/bin/env bash
# install.sh — Install packages for silver desktop
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

install_path="$REPO_DIR/install"
install_ubuntu="$install_path/ubuntu"

info "Running Ubuntu bootstrap..."
"$install_ubuntu/bootstrap.sh"
"$install_ubuntu/snap.sh"
"$install_ubuntu/filesystem.sh"
"$install_ubuntu/docker.sh"

info "Installing window manager..."
"$install_ubuntu/hyperland.sh"

info "Running shared installers..."
bash "$install_path/_oh-my-zsh.sh"
bash "$install_path/_tmux.post-install.sh"

info "Install complete — run configure.sh and links.sh"
