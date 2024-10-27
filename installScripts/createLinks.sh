#!/bin/bash
# This script will create symbolic links between configuration files
# (under ~/.config) and their expected place at home (~).
# With this kind of link we can keep all the configurations under the same folder/repo.
# Author: brunodles <github.com/brunodles>

declare DOTFILES_DIR="$HOME/dotfiles"
declare BACKUP_DIR="$HOME/dotfiles/backup/$(date +%Y-%m-%d_%H-%M-%S)"
mkdir -p "$BACKUP_DIR"

stack=""
stackUp(){
  stack="$stack  "
}
stackDown(){
  stack=${stack::-2}
}
log() {
  echo "#$stack $@"
}
logC() {
  echo "$@"
}

run() {
  logC "$@"
  $@
}

# Fix paths by replacing '~' with $HOME
fixPath() {
  echo ${1/#~\//$HOME/}
}

# Backup target folder into [DOTFILES_DIR/backup]
# Params:
#   1. path of what needs to be saved
backup() {
  if [[ "$1" == *"~"* ]]; then
    backup $(fixPath "$1")
    return
  fi
  stackUp
  log "backup $1"
  if [ -e $1 ]; then
    #run "cp -r '$1' '$BACKUP_DIR/${1##*/}'"
    run cp -r "$1" "$BACKUP_DIR/${1##*/}"
  else
    log "  cannot backup, file or directory not found $1"
  fi
  stackDown
}

# Delete file or directory
remove() {
  if [[ "$1" == *"~"* ]]; then
    remove $(fixPath "$1")
    return
  fi
  stackUp
  log "remove $1"
  if [ -e $1 ]; then
    #run "rm -rd '$1'"
    run rm -rd "$1"
  elif [ -f $1 ]; then
    #run "rm '$1'"
    run rm "$1"
  elif [ -d $1 ]; then
    #run "rm -rd '$1'"
    run rm -rd "$1"
  else
    log "  file not found in $1"
  fi
  stackDown
}

# Create a symbolic link
# Params:
#   1. The path of the configuration application. A link will be generated in this path.
#   2. The new configuration. The path to the actual file.
link() {
  if [[ "$1" == *"~"* ]] || [[ "$2" == *"~"* ]]; then
    link $(fixPath "$1") $(fixPath "$2")
    return
  fi
  stackUp
  log "link $1 $2"
  #run "ln -s '$2' '$1'"
  run ln -s "$2" "$1"
  stackDown
}

# Copy the original content of configuration into backup folder
# Then link it to my configuration
# Params:
#   1. The path of the configuration application
#   2. The new configuration.
backupAndLink() {
  stackUp
  log "backupAndLink $1 $2"
#  cp "$1" "$BACKUP_DIR/${1:/}"
  backup "$1"
#  rm "$1"
  remove "$1"
#  ln -s "${DOTFILES_DIR}/$2" "$1"
  link "$1" "$2"
  stackDown
}

# Copy the original content of configuration into backup folder
# Then link my configuration into that path
# This one differs from the above by receiving only one parameter that will link
# something in '~/.config' with something with same name in [DOTFILES_DIR]
# Params:
#   1. The name of whay should be linked
backupAndLinkConfig() {
  stackUp
  log "backupAndLinkConfig $1"
  backupAndLink "~/.config/$1" "${DOTFILES_DIR}/$1"
  stackDown
}

# Sample of what will happen to link zsh
# Link ~/.zshrc
#cp ~/.zshrc ~/.config/backup/
#rm ~/.zshrc
#ln -s ~/.config/zsh/zshrc ~/.zshrc

# zsh will be linked into the "~/.config/zsh". 
# All configurations will still point into the '.config', 
# but it will be linked back into this repo
log "zsh"
backup "~/.zshrc"
remove "~/.zshrc"
backupAndLinkConfig "zsh"
link "~/.zshrc" "~/.config/zsh/zshrc"

# Simple configurations that already remain in the '~/.config' dir
backupAndLinkConfig "i3"
backupAndLinkConfig "i3blocks"
backupAndLinkConfig "i3status"
backupAndLinkConfig "alacritty"
backupAndLinkConfig "compton.conf"
backupAndLinkConfig "wallpaper"

