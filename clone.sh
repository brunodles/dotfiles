DOTFILES_DIR="$HOME/dotfiles"
REPO="https://github.com/brunodles/dotfiles.git"

if [ ! -d "$DOTFILES_DIR" ]; then
  cd "$HOME"
  git clone "$REPO" "$DOTFILES_DIR"
fi

cd "$DOTFILES_DIR"
