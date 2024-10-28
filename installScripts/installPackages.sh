#!/bin/bash
# Install Packages for having this running
# Author: Bruno de Lima <github.com/brunodles>

# These variables will be used to accumulate the contents
declare -a _linux_shared=()
declare -a _linux_servers=()
declare -a _linux_ui=()

declare -a _brew=()
declare -a _brew_cask=()


shared() {
  _linux_shared+=($@)  
}
server() {
  _linux_servers+=($@)
}
lui() {
  _linux_ui+=($@)
}

brew() {
  _brew+=($@)
}
cask() {
  _brew_cask+=($@)
}


where() {
  echo $(command -v $1)
}
linuxUpdatePackages() {
  echo "LinuxUpdatePackages"
  if [ ! -z "$(where pacman)" ]; then
    sudo pacman -Syu
  elif [ ! -z "$(where apt)" ]; then
    sudo apt update
  else
    echo $@
  fi
}

linuxInstall() {
  echo "LinuxInstall $@"
  if [ ! -z "$(where pacman)" ]; then
    sudo pacman -S $@
  elif [ ! -z "$(where apt)" ]; then
    sudo apt install -y $@
  else
    echo $@
  fi
}

# Linux
shared base-devel build-essential
shared vim curl git tmux zsh
shared neovim
## docker requires a custom instalation script
#shared docker docker-compose-plugin
#shared docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
lui firefox alacritty feh compton i3 i3blocks
#server ?

# Mac
brew vim curl git tmux zsh
brew neovim
brew docker docker-compose-plugin
cask alacritty

declare uname=$(uname)
declare -a tools=()
tools+=()
case $uname in
  "Linux")
    tools+=(${_linux_shared[@]})
    if [ ! -z "$XDG_CURRENT_DESKTOP" ]; then
      tools+=(${_linux_ui[@]})
    else
      tools+=(${_linux_server[@]})
    fi
    if [ -z "$(where docker)" ] || [ -z "$(where docker-compose)" ]; then
      tools+=(docker docker-compose)
    fi
    ;;
  "Darwin")
    tools+=(${_brew[@]})
    tools+=(${_brew_cask[@]})
    ;;
esac
if [ ! -e "$HOME/.oh-my-zsh" ]; then
  tools+=("oh-my-zsh")
fi

echo "This script will install: \"${tools[@]}\"."
read -p ":: Continue install? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1


case $uname in
  "Linux")
    linuxUpdatePackages
    linuxInstall ${_linux_shared[@]}
    if [ ! -z "$XDG_CURRENT_DESKTOP" ]; then
      linuxInstall ${_linux_ui[@]}
    else
      linuxInstall ${_linux_server[@]}
    fi
    ;;
  "Darwin")
    sudo brew install ${_brew[@]}
    sudo brew install --cask install ${_brew_cask[@]}
    ;;
esac
#install ${tools[@]}

# Zsh
if [[ " ${tools[*]} " == *" oh-my-zsh "* ]]; then
  echo install oh-my-zsh
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Docker, DockerCompose
if [[ " ${tools[*]} " == *" docker "* ]]; then
  echo Installl docker
  if [ ! -z "$(where pacman)" ]; then
    wget https://download.docker.com/linux/static/stable/x86_64/docker-27.2.1.tgz -qO- | tar xvfz - docker/docker --strip-components=1
    sudo mv ./docker /usr/local/bin
    curl -O https://desktop.docker.com/linux/main/amd64/172550/docker-desktop-x86_64.pkg.tar.zst
    sudo pacman -U ./docker-desktop-x86_64.pkg.tar.zst
  else
    local tempFile="/tmp/docker-desktop-amd64.deb"
    if [ -e "$tempFile" ]; then
      curl -o $tempFile https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb
    fi
    sudo apt install $tempFile
    #rm -f $tempFile
  fi
fi

