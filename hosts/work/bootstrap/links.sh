#!/usr/bin/env bash
# links.sh — Symlink dotfiles for macOS work machine
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

link="$REPO_DIR/scripts/install/link"
home_config="$HOME/.config"
repo_config="$REPO_DIR/dotfiles"

mkdir -p "$home_config"

info "Linking dotfiles..."
bash "$link" "$repo_config/.vimrc" "$HOME/.vimrc" 2>/dev/null || {
  info "  scripts/install/link not found — using ln -sf"
  ln -sf "$repo_config/.vimrc" "$HOME/.vimrc"
  ln -sf "$repo_config/tmux/tmux.conf" "$home_config/tmux/tmux.conf"
  ln -sf "$repo_config/zsh" "$home_config/zsh"
  ln -sf "$home_config/zsh/zshrc" "$HOME/.zshrc"
}

info "Links complete"
