#!/usr/bin/env bash

install_path="$HOME/dotfiles/install"
install_ubuntu="$install_path/ubuntu"

# Install common
$install_ubuntu/bootstrap.sh
$install_ubuntu/snap.sh
$install_ubuntu/filesystem.sh

$install_ubuntu/docker.sh

# Window Manager - HyperLand
$install_ubuntu/hyperland.sh

# Window Manager - i3wm
#$install_ubuntu/i3wm.sh
#$install_path/_fonts.sh

# other
$install_path/_samba.post-install.sh
$install_path/_oh-my-zsh.sh
$install_path/_tmux.post-install.sh


# dotfile links
link="$HOME/dotfiles/scripts/install/link"
# link source target
home_local="$HOME/.local"
home_config="$HOME/.config"
repo_config="$HOME/dotfiles/dotfiles"
link "$repo_config/.vimrc" "$HOME/.vimrc"
link "$repo_config/tmux/tmux.conf" "$home_config/tmux/tmux.conf"
link "$repo_config/zsh" "$home_config/zsh"
link "$repo_config/i3" "$home_config/i3"
link "$repo_config/i3blocks" "$home_config/i3blocks"
link "$repo_config/i3status" "$home_config/i3status"
link "$repo_config/compton.conf" "$home_config/compton.conf"
link "$repo_config/alacritty" "$home_config/alacritty"
link "$repo_config/ghostty" "$home_config/ghostty"
link "$home_config/zsh/zshrc" "$HOME/.zshrc"

mkdir "$home_local"
mkdir "$home_local/bin"
mkdir "$home_local/fbin"
cp -r "./home/.local/bin/" "$home_local/bin"
cp -r "./home/.local/fbin/" "$home_local/fbin"

