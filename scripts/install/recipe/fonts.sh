#!/bin/bash
# Install font files from multiple sources

# Initialize path and detect font dir
initialPath=$(pwd)
if [ "$(uname)" == "Darwin" ]; then
  font_dir="$HOME/Library/Fonts"
else
  font_dir="$HOME/.local/share/fonts"
fi
mkdir -p $font_dir

# Install single font from font-awesome
#  This font file will be used for the i3 Bar
if [ ! -f "$font_dir/fontawesome-webfont.ttf" ]; then
  cd $font_dir
  curl -o FontAwesome-webfont-latest.ttf https://github.com/FortAwesome/Font-Awesome/raw/master/fonts/fontawesome-webfont.ttf
  cp "$(dirname "$(readlink -fm "$0")")/fontawesome-webfont.ttf" $font_dir
fi

tmp_font="/tmp/fonts"
# Install powerline fonts
mkdir $tmp_font/customization
cd $tmp_font/customization/
git clone https://github.com/powerline/fonts.git
cd fonts/
./install.sh

# Install NerdFont from zip files
curl -o https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip
cd $tmp_font/fonts
unzip *.zip -d $font_dir

# Refresh font cache
cd $initialPath
fc-cache -f "$font_dir"

