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

# linker
#~/dotfiles/scripts/linker link
# ~/dotfiles/tmux/tmux.conf
home_config="$HOME/.config"
rm -rd "$home_config/tmux/tmux.conf"
rm -rd "$home_config/compton.conf"
rm -rd "$home_config/home/.vimrc"
rm -rd "$home_config/zsh"
rm -rd "$home_config/i3"
rm -rd "$home_config/i3blocks"
rm -rd "$home_config/i3status"
rm -rd "$home_config/alacritty"
rm -rd "$home_config/ghostty"

#ln -s <SOURCE> <TARGET>
repo_config="$HOME/dotfiles/dotfiles"
ln -s "$repo_config/.vimrc" "$HOME/.vimrc"
ln -s "$repo_config/tmux/tmux.conf" "$home_config/tmux/tmux.conf"
ln -s "$repo_config/zsh" "$home_config/zsh"
ln -s "$repo_config/i3" "$home_config/i3"
ln -s "$repo_config/i3blocks" "$home_config/i3blocks"
ln -s "$repo_config/i3status" "$home_config/i3status"
ln -s "$repo_config/compton.conf" "$home_config/compton.conf"
ln -s "$repo_config/alacritty" "$home_config/alacritty"
ln -s "$repo_config/ghostty" "$home_config/ghostty"

mkdir "$HOME/.local"
ln -s "./home/.local/bin" "$HOME/.local/bin"
ln -s "./home/.local/fbin" "$HOME/.local/fbin"
ln -s "$home_config/zsh/zshrc" "$HOME/.zshrc"

