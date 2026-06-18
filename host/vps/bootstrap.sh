#!/usr/bin/env bash

install_path="$HOME/dotfiles/install"
install_ubuntu="$install_path/ubuntu"

$install_ubuntu/bootstrap.sh
$install_ubuntu/ufw.sh
$install_ubuntu/filesystem.sh
$install_ubuntu/docker.sh
$install_path/_oh-my-zsh.sh
$install_path/_tmux.post-install.sh

# Dockge
dockge_path="$HOME/dotfiles/host/vps/dockge"
mkdir -p /opt
ln -s "$dockge_path/stacks" /opt/stacks
ln -s "$dockge_path/dockage" /opt/self

# Traefik: Create docker proxy network
docker network create proxy

# Hermes:
mkdir -p "$HOME/workspace"
