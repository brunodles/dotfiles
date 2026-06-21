#!/usr/bin/env bash
# links.sh — Symlink dotfiles for silver desktop
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

link="$REPO_DIR/scripts/install/link"
home_local="$HOME/.local"
home_config="$HOME/.config"
repo_config="$REPO_DIR/dotfiles"

mkdir -p "$home_config" "$home_local/bin" "$home_local/fbin"

info "Linking dotfiles..."
bash "$link" "$repo_config/.vimrc" "$HOME/.vimrc"
bash "$link" "$repo_config/tmux/tmux.conf" "$home_config/tmux/tmux.conf"
bash "$link" "$repo_config/zsh" "$home_config/zsh"
bash "$link" "$repo_config/i3" "$home_config/i3"
bash "$link" "$repo_config/i3blocks" "$home_config/i3blocks"
bash "$link" "$repo_config/i3status" "$home_config/i3status"
bash "$link" "$repo_config/compton.conf" "$home_config/compton.conf"
bash "$link" "$repo_config/alacritty" "$home_config/alacritty"
bash "$link" "$repo_config/ghostty" "$home_config/ghostty"
bash "$link" "$home_config/zsh/zshrc" "$HOME/.zshrc"

info "Copying local scripts..."
cp -r "$HOST_DIR/home/.local/bin/"* "$home_local/bin/" 2>/dev/null || true
cp -r "$HOST_DIR/home/.local/fbin/"* "$home_local/fbin/" 2>/dev/null || true

info "Silver links complete"
