#!/bin/bash
# params - the path of the font files

# Initialize path and detect font dir
initialPath=$(pwd)
if [ "$(uname)" == "Darwin" ]; then
  font_dir="$HOME/Library/Fonts"
else
  font_dir="$HOME/.local/share/fonts"
  mkdir -p $font_dir
fi

cp "$@" $font_dir

# Refresh font cache
fc-cache -f "$font_dir"

