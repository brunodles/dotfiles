install_path="/home/$USER/dotfiles/install"
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
rm -rd "/home/$USER/.config/tmux/tmux.conf"
rm -rd "/home/$USER/.config/compton.conf"
rm -rd "/home/$USER/.config/home/.vimrc"
rm -rd "/home/$USER/.config/zsh"
rm -rd "/home/$USER/.config/i3"
rm -rd "/home/$USER/.config/i3blocks"
rm -rd "/home/$USER/.config/i3status"
rm -rd "/home/$USER/.config/alacritty"
rm -rd "/home/$USER/.config/ghostty"


#ln -s <SOURCE> <TARGET>
ln -s "/home/$USER/dotfiles/dotfiles/tmux/tmux.conf" "/home/$USER/.config/tmux/tmux.conf"
ln -s "/home/$USER/dotfiles/dotfiles/compton.conf" "/home/$USER/.config/compton.conf"
ln -s "/home/$USER/dotfiles/dotfiles/home/.vimrc" "/home/bruno/.vimrc"
ln -s "/home/$USER/dotfiles/dotfiles/zsh" "/home/$USER/.config/zsh"
ln -s "/home/$USER/dotfiles/dotfiles/i3" "/home/$USER/.config/i3"
ln -s "/home/$USER/dotfiles/dotfiles/i3blocks" "/home/$USER/.config/i3blocks"
ln -s "/home/$USER/dotfiles/dotfiles/i3status" "/home/$USER/.config/i3status"
ln -s "/home/$USER/dotfiles/dotfiles/alacritty" "/home/$USER/.config/alacritty"
ln -s "/home/$USER/dotfiles/dotfiles/ghostty" "/home/$USER/.config/ghostty"

mkdir "/home/$USER/.local"
ln -s "./home/.local/bin" "/home/$USER/.local/bin"
ln -s "./home/.local/fbin" "/home/$USER/.local/fbin"
ln -s "/home/$USER/.config/zsh/zshrc" "/home/$USER/.zshrc"

compaudit
