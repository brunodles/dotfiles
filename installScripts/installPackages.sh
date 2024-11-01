#!/bin/bash
# Install Packages for having this running
# Author: Bruno de Lima <github.com/brunodles>

source installUtils.sh

# Linux
  shared base-devel build-essential
  shared vim curl git tmux zsh
  shared neovim

## Docker - requires a custom instalation script
  #shared docker docker-compose-plugin
  #shared docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  # disable because I need to think on how declare those custom install scripts

## UI customization / Desktop Environment
  lui firefox feh compton i3 i3blocks
  #lui alacritty # disable because I need to think on how declare those custom install scripts

## Servers 
  #servers ?

## Android
  shared pidcat-git
  lui scrcpy

# Mac
  brew vim curl git tmux zsh
  brew neovim
#  brew docker docker-compose-plugin
  brew scrcpy pidcat
#  cask alacritty


executeInstall

