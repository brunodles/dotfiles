#!/bin/bash

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

