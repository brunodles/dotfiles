#!./install/interpreter.sh
# Install configuration script
# This script is executed by a custom script interpreter that will perform the correct install script depending on the
# platform and if it desired for that platform.
# Author: Bruno de Lima <github.com/brunodles>

# The configuration is both a script and a 3 column table,
# where each column represents the platform, the command and the package
# 1 - the platform key alias. Eg.: Ar for Arch Linux, Ud for Ubuntu Desktop.
# 2 - the command. Some commands are aliased but any command can be performed
# 3 - the packages or parameters. What would be passed into the command being performed
# See the platform and examples bellow

# Platforms configuration keys
# key, System
#  Ar,       Arch Linux
#  Ap,     Alpine Linux
#  Ud,   Ubuntu Desktop
#  Us,   Ubuntu  Server
#  R , Raspbian
#  Rd, Raspbian Desktop
#  Rs, Raspberry Server
#   M, MacOs (brew)
#   *, all

# Command Alias
# Key, Command
#    i, will be translated to one install command of the platform (apt install, pacman -S, apk add, brew install)
# cask, MacOs only. Map one dependency to be installed using 'brew install --cask'.
#    *, any other command will be executed as command line
#    ?, custom recipies at 'recipies/' folder might override the install command

# Pre install
UdUs sudo apt update
Ud   i snapd
Ud   snap snap-store
Ud   echo "Snap store installed"


# Terminal shell
UdUs i build-essential
Ar   i base-devel
*    i curl wget git
*    i vim
*    i neovim
M cask neovim
*    i tmux
*    i zsh
*    i oh-my-zsh
* echo "Terminal shell installed"

# File System
ArApUdUs i samba
ArApUdUs i unzip
# Usb + Disk Management
ArUd  i udisks2
ArUd  i usbutils
ArUd  i sshfs
Ar    i gvfs gvfs-smb
*  echo "File system" 

# Ghostty
Ar pacman ghostty
M  cask ghostty
Ud snap ghostty --classic

# Containers
## Docker - requires a custom install script.
### Disable because I need to think on how declare those custom install scripts
### Also have a complex installation process. Replaced by Podman
# * i docker docker-compose-plugin
# * i docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
## Podman
Ar   i arch-install-scripts
ArUd i lxc podman

# UI customization / Desktop Environment
## i3wm
ArUd  i firefox feh i3 i3blocks
#au  i compton

### File namanager
ArUd  i thunar thunar-volman thunar-archive-plugin

### Network and Bluetooth Managers and Applets
ArUd  i network-manager network-manager-applet
ArUd  i blueman

## hyprland
Ud  i hyprland wofi dolphin hyprpaper

## Monitor/Display manager
Ar i xorg-xrandr
Ud i x11-xserver-utils 

## Graphical Library
Ar    i glu webkit2gtk-4.1
Ud    i libglu1-mesa libwebkit2gtk-4.1-dev
ArUd  i fonts

#au i alacritty # disable because I need to think on how declare those custom install scripts

# Servers 
  #servers ?

## Android
#aum i pidcat-git
ArUd i scrcpy

# Mac
