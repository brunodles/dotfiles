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
sudo ln -s "$dockge_path/stacks" /opt/stacks
sudo ln -s "$dockge_path/dockge" /opt/self
sudo chown $USER "$dockge_path/stacks"
sudo chown $USER "$dockge_path/dockge"

# Traefik: Create docker proxy network
sudo docker network create proxy

# Hermes:
mkdir -p "$HOME/workspace"

# dotfile links
link="$HOME/dotfiles/scripts/install/link"
# link source target
home_config="$HOME/.config"
repo_config="$HOME/dotfiles/dotfiles"
link "$repo_config/.vimrc" "$HOME/.vimrc"
link "$repo_config/tmux/tmux.conf" "$home_config/tmux/tmux.conf"
link "$repo_config/zsh" "$home_config/zsh"
link "$home_config/zsh/zshrc" "$HOME/.zshrc"

