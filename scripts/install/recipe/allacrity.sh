#!/bin/bash
# Install Alacritty
# Build from source is required for alacritty because the package systems are not consistent.
# They don't have the same version available.
# Build alacritty from source in a docker image. Compilation happens inside a docker container.
# https://github.com/mdedonno1337/docker-alacritty

local docker_version=$(docker --version)
if [[ -z "$docker_version" ]]; then
  echo "Docker not found!"
  return 1
fi

local repo_dir="~/dotfiles/repo"
mkdir -p $repo_dir 
cd $repo_dir
git clone git@github.com:mdedonno1337/docker-alacritty.git
cd docker-alacritty
make
sudo mv alacritty /usr/bin

