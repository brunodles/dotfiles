#!/usr/bin/env bash
# links.sh — Symlink dotfiles for media server
source "$HOME/dotfiles/scripts/bootstrap/_log.source.sh"
source "$HOME/dotfiles/scripts/bootstrap/_env.source.sh"

link="$SCRIPT_BOOTSTRAP_DIR/link"
config_source="$REPO_DIR/dotfiles"
config_out="$HOME/.config"

mkdir -p "$config_out"

info "Linking dotfiles..."
"$link" "$config_source/.vimrc" "$HOME/.vimrc"
"$link" "$config_source/tmux/tmux.conf" "$config_out/tmux/tmux.conf"
"$link" "$config_source/zsh" "$config_out/zsh"
"$link" "$config_out/zsh/zshrc" "$HOME/.zshrc"

info "Media links complete"
