#!/usr/bin/env bash
# install.sh — Install software for media server
source "$HOME/dotfiles/scripts/bootstrap/_log.source.sh"
source "$HOME/dotfiles/scripts/bootstrap/_env.source.sh"

install_ubuntu="$SCRIPT_INSTALL_DIR/ubuntu"

info "Running Ubuntu bootstrap..."
"$install_ubuntu/bootstrap.sh"

info "Setting up Docker..."
"$install_ubuntu/docker.sh"

info "Running shared installers..."
"$SCRIPT_INSTALL_DIR/_oh-my-zsh.sh"
"$SCRIPT_INSTALL_DIR/_tmux.post-install.sh"
"$SCRIPT_INSTALL_DIR/_samba.post-install.sh"

info "Media install complete — run configure.sh next"
