#!/data/data/com.termux/files/usr/bin/bash
# links.sh — Symlink dotfiles for android phone
source "$HOME/dotfiles/scripts/bootstrap/_log.source.sh"
source "$HOME/dotfiles/scripts/bootstrap/_env.source.sh"

link="$SCRIPT_BOOTSTRAP_DIR/link"
config_source="$REPO_DIR/dotfiles"
home_local="$HOME/.local"
home_config="$HOME/.config"
host_phone="$REPO_DIR/hosts/phone"

mkdir -p "$home_config" "$home_local/bin" "$home_local/fbin"

info "Linking dotfiles..."
"$link" "$config_source/.vimrc" "$HOME/.vimrc"
"$link" "$config_source/tmux/tmux.conf" "$home_config/tmux/tmux.conf"
"$link" "$config_source/zsh" "$home_config/zsh"
"$link" "$home_config/zsh/zshrc" "$HOME/.zshrc"

info "Copying local scripts..."
cp -r "$host_phone/home/.local/bin/"* "$home_local/bin/" 2>/dev/null || true
cp -r "$host_phone/home/.local/fbin/"* "$home_local/fbin/" 2>/dev/null || true

info "Silver links complete"
