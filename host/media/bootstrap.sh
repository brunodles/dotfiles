#!/usr/bin/env bash

install_path="$HOME/dotfiles/install"
install_ubuntu="$install_path/ubuntu"

# Install common
$install_ubuntu/bootstrap.sh
#$install_ubuntu/snap.sh
$install_ubuntu/filesystem.sh

$install_ubuntu/docker.sh

# other
$install_path/_samba.post-install.sh
$install_path/_oh-my-zsh.sh
$install_path/_tmux.post-install.sh


# Traefik: Create docker proxy network
sudo docker network create proxy

# dotfile links
link="$HOME/dotfiles/scripts/install/link"
# link source target
home_config="$HOME/.config"
repo_config="$HOME/dotfiles/dotfiles"
link "$repo_config/.vimrc" "$HOME/.vimrc"
link "$repo_config/tmux/tmux.conf" "$home_config/tmux/tmux.conf"
link "$repo_config/zsh" "$home_config/zsh"
link "$home_config/zsh/zshrc" "$HOME/.zshrc"

