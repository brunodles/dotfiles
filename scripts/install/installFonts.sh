#!/bin/bash
# Install font files from multiple sources

# Initialize path and detect font dir
initialPath=$(pwd)
if [ "$(uname)" == "Darwin" ]; then
  font_dir="$HOME/Library/Fonts"
else
  font_dir="$HOME/.local/share/fonts"
  mkdir -p $font_dir
fi

# Install single font from font-awesome
#  This font file will be used for the i3 Bar
cd $font_dir
curl -o FontAwesome-webfont-latest.ttf https://github.com/FortAwesome/Font-Awesome/raw/master/fonts/fontawesome-webfont.ttf
cp "$(dirname "$(readlink -fm "$0")")/fontawesome-webfont.ttf" $font_dir

# Install powerline fonts
mkdir $initialPath/customization
cd $initialPath/customization/
git clone https://github.com/powerline/fonts.git
cd fonts/
./install.sh

# Install NerdFont from zip files
cd $initialPath/fonts
unzip *.zip -d $font_dir

# Refresh font cache
cd $initialPath
fc-cache -f "$font_dir"

