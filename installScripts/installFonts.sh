#!/bin/bash

initialPath=$(pwd)

if [ "$(uname)" == "Darwin" ]; then
  font_dir="$HOME/Library/Fonts"
else
  font_dir="$HOME/.local/share/fonts"
  mkdir -p $font_dir
fi

cd $font_dir
curl -o FontAwesome-webfont-latest.ttf https://github.com/FortAwesome/Font-Awesome/raw/master/fonts/fontawesome-webfont.ttf

mkdir $initialPath/customization
cd $initialPath/customization/
git clone https://github.com/powerline/fonts.git
cd fonts/
./install.sh

fc-cache -f "$font_dir"

cd $initialPath

