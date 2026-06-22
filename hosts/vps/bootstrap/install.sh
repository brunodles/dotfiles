#!/usr/bin/env bash
# install.sh — Install packages for VPS
source "$HOME/dotfiles/scripts/bootstrap/_log.source.sh"
source "$HOME/dotfiles/scripts/bootstrap/_env.source.sh"

install_ubuntu="$SCRIPT_INSTALL_DIR/ubuntu"

info "Running Ubuntu bootstrap..."
"$install_ubuntu/bootstrap.sh"
"$install_ubuntu/ufw.sh"
"$install_ubuntu/filesystem.sh"
"$install_ubuntu/docker.sh"

info "Running shared installers..."
"$install_path/_oh-my-zsh.sh"
"$install_path/_tmux.post-install.sh"

info "Install complete — run configure.sh and links.sh"
