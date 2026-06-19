# Work — macOS Workstation

My development machine at work, running macOS.

## Setup

```bash
git clone https://github.com/brunodles/dotfiles.git
cd dotfiles
bash host/work/bootstrap.sh
```

## What it installs

| Tool | Source |
|------|--------|
| Xcode Command Line Tools | `xcode-select` |
| Homebrew | Official install script |
| curl, wget, git, vim, neovim | `brew install` |
| tmux, zsh, ripgrep, fzf | `brew install` |
| Ghostty | `brew install --cask` |
| JetBrains Mono Nerd Font | `brew install --cask` |
| Oh My Zsh + p10k | `install/_oh-my-zsh.sh` |
| Dotfiles (zsh, tmux, vim) | Symlinks via `scripts/install/link` |

## Post-setup

- Open **Ghostty** and confirm the theme
- Open **neovim** and let Lazy/mason install plugins
- `chsh -s /bin/zsh` is done by the bootstrap
