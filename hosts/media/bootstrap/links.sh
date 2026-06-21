#!/usr/bin/env bash
# links.sh — Symlink dotfiles for media server
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

link="$REPO_DIR/scripts/install/link"
home_config="$HOME/.config"
repo_config="$REPO_DIR/dotfiles"

mkdir -p "$home_config"

info "Linking dotfiles..."
bash "$link" "$repo_config/.vimrc" "$HOME/.vimrc"
bash "$link" "$repo_config/tmux/tmux.conf" "$home_config/tmux/tmux.conf"
bash "$link" "$repo_config/zsh" "$home_config/zsh"
bash "$link" "$home_config/zsh/zshrc" "$HOME/.zshrc"

info "Media links complete"
