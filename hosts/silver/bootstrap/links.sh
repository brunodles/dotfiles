#!/usr/bin/env bash
# links.sh — Symlink dotfiles for silver desktop
source "$HOME/dotfiles/scripts/bootstrap/_log.source.sh"
source "$HOME/dotfiles/scripts/bootstrap/_env.source.sh"

link="$SCRIPT_BOOTSTRAP_DIR/link"
config_source="$REPO_DIR/dotfiles"
home_local="$HOME/.local"
home_config="$HOME/.config"
host_silver="$REPO_DIR/hosts/silver"

mkdir -p "$home_config" "$home_local/bin" "$home_local/fbin"

info "Linking dotfiles..."
"$link" "$config_source/.vimrc" "$HOME/.vimrc"
"$link" "$config_source/tmux/tmux.conf" "$home_config/tmux/tmux.conf"
"$link" "$config_source/zsh" "$home_config/zsh"
"$link" "$config_source/i3" "$home_config/i3"
"$link" "$config_source/i3blocks" "$home_config/i3blocks"
"$link" "$config_source/i3status" "$home_config/i3status"
"$link" "$config_source/compton.conf" "$home_config/compton.conf"
"$link" "$config_source/alacritty" "$home_config/alacritty"
"$link" "$config_source/ghostty" "$home_config/ghostty"
"$link" "$home_config/zsh/zshrc" "$HOME/.zshrc"

info "Copying local scripts..."
cp -r "$host_silver/home/.local/bin/"* "$home_local/bin/" 2>/dev/null || true
cp -r "$host_silver/home/.local/fbin/"* "$home_local/fbin/" 2>/dev/null || true

info "Silver links complete"
