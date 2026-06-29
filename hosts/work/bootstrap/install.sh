#!/usr/bin/env bash
# install.sh — Install software for macOS work machine
source "$HOME/dotfiles/scripts/bootstrap/_log.source.sh"
source "$HOME/dotfiles/scripts/bootstrap/_env.source.sh"

if [[ "$(uname)" != "Darwin" ]]; then
  error "This script is for macOS only."
  exit 1
fi

# Xcode
info "Checking Xcode Command Line Tools..."
if xcode-select -p &>/dev/null; then
  info "  Already installed"
else
  info "  ⚠️  This will open a GUI prompt. Click Install."
  xcode-select --install
  info "  ⏳ Waiting for installation to finish..."
  until xcode-select -p &>/dev/null; do
    sleep 5
  done
  info "  Installed"
fi

info "Installing Homebrew..."
bash "$REPO_DIR/install/_homebrew.sh"
echo ""
echo "Installing base packages..."
brew install curl wget git vim neovim tmux zsh ripgrep fzf
brew install --cask neovim ghostty font-jetbrains-mono-nerd-font


info "Installing Oh My Zsh..."
bash "$REPO_DIR/install/_oh-my-zsh.sh"

info "Install complete — run configure.sh and links.sh"
