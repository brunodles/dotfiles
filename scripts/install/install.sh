#!/bin/bash
# Instal Script.
# Reads a configuration file that can aggregate multiple systems.
# Author: Bruno de Lima <github.com/brunodles>
#
# The configuration is basically a table with two columns. Separated by pipe ('|')
#  1 - system
#  2 - packages
#
# Each system is defined by the following characters
#   * - All Systems
#   a - Arch Linux
#   u - Ubuntu Desktp
#   s - Server / Ubuntu Server
#   p - Raspiberry Pi
#   m - MacOs
#
# Mac Os configuration
#   Every mac os installation will use 'brew' command, unless configured to use cask
#  Mb - MacOs Homebrew
#  Mc - MacOs Cask
#   Add an 'Mc' line to use 'cask' instead of 'brew'
#
# Example:
# *   | git            # install git on all systems
# aum | zsh oh-my-zsh  # install zsh and oh-my-zsh on Arch Linux, Ubuntu Desktop and Mac Os
# sp  | openssh-server # install open ssh server
# aum | allacrity      # install allacrity
# Mc  | allacrity      # configure allacrity to use 'cask'
#
#

readonly CONFIG_FILE="$(dirname $0)/.install"
readonly RECIPE_DIR="$(dirname $0)/rcp"

declare -a PACKAGES=()
while IFS=$'\n' read -r line; do
  system=$(echo "${line%|*}" | xargs -0)
  packages=$(echo "${line#*|}" | xargs -0)
  case "$system" in
    "#"*|" "*|"")
      continue
      ;;
    *)
      PACKAGES+=($packages)
      echo "$system > $packages" 
      ;;
  esac
done <"$CONFIG_FILE"

echo "This script will install: \"${PACKAGES[@]}\"."
read -p ":: Continue install? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

declare -a INSTALL_COMMAND=()
declare -a INSTALL_RECIPIES=()
for (( i=0; i<${#PACKAGES[@]}; i++ )); do
  package="${PACKAGES[$i]}"
  # TODO: if the 'package' exist into the 'rcp' folder it should install from there.
  # Otherwise add the package into the install command package.
  if [ -e "$RECIPE_DIR/${package}.sh" ]; then
    INSTALL_RECIPIES+=($package)
  else
    INSTALL_COMMAND+=($package)
  fi
done

# Install from package manager
echo "Install ${INSTALL_COMMAND[@]}"
# TODO: add execute command

# Install from Recipies
for (( i=0; i<${#INSTALL_RECIPIES[@]}; i++ )); do
  package="${INSTALL_RECIPIES[$i]}"
  echo "Install '$package' from recipe."
done

# Post Install scripts
for (( i=0; i<${#PACKAGES[@]}; i++ )); do
  package="${PACKAGES[$i]}"
  if [ -e "$RECIPE_DIR/${package}.after.sh" ]; then
    echo "Post-Install for '$package'."
  fi
done

