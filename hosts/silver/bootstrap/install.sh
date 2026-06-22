#!/usr/bin/env bash
# install.sh — Install packages for silver desktop
source "$HOME/dotfiles/scripts/bootstrap/_log.source.sh"
source "$HOME/dotfiles/scripts/bootstrap/_env.source.sh"

install_ubuntu="$SCRIPT_INSTALL_DIR/ubuntu"

info "Running Ubuntu bootstrap..."
"$install_ubuntu/bootstrap.sh"
"$install_ubuntu/snap.sh"
"$install_ubuntu/filesystem.sh"
"$install_ubuntu/docker.sh"

info "Installing window manager..."
"$install_ubuntu/hyperland.sh"

info "Running shared installers..."
"$SCRIPT_INSTALL_DIR/_oh-my-zsh.sh"
"$SCRIPT_INSTALL_DIR/_tmux.post-install.sh"

info "Install complete — run configure.sh and links.sh"
