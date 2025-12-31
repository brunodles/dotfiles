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
#   a - Arch Linux + UI
#   u - Ubuntu + UI
#   s - Server / Ubuntu Server
#   p - Raspiberry Pi + UI
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
#

readonly CONFIG_FILE="$(dirname $0)/install.config"
readonly RECIPE_DIR="$(dirname $0)/rcp"
readonly UNAME="$(uname)"

declare -a SYSTEMS=()
declare -a PACKAGES=()
declare INSTALL_COMMAND=""

case "${UNAME}" in
  "Linux")
    if [ -z "$XDG_CURRENT_DESKTOP" ]; then
      SYSTEMS+=("s")
      INSTALL_COMMAND="apt install"
    else
      linux_id=$(awk -F= '/^ID/{print $2}' /etc/os-release)
      case "$linux_id" in
        "arch")
          SYSTEMS+=("a")
          INSTALL_COMMAND="pacman -S"
          ;;
        "ubuntu")
          SYSTEMS+=("u")
          INSTALL_COMMAND="apt install"
          ;;
        "raspbian")
          SYSTEMS+=("p")
          INSTALL_COMMAND="apt install"
          ;;
      esac
    fi
    ;;
    "Darwin")
      SYSTEMS+=("m" "Mc" "Mb")
      ;;
esac


#echo "Reading config file:"
while IFS=$'\n' read -r line; do
  system=$(echo "${line%|*}" | xargs -0)
  packages=$(echo "${line#*|}" | xargs -0)
  case "$system" in
    "#"*|" "*|"")
      continue
      ;;
    "* "*)
      PACKAGES+=($packages)
#      echo "    $system > $packages" 
      continue
      ;;
  esac
  for s in "${SYSTEMS[@]}"; do
    if [[ "$system" == *"$s"* ]]; then
      PACKAGES+=($packages)
#      echo "    $system > $packages" 
      break
    fi
  done
done <"$CONFIG_FILE"

echo "This device was detected as \"${SYSTEMS[@]}\"."
echo "This script will install: \"${PACKAGES[@]}\"."
read -p ":: Continue install? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

declare -a INSTALL_COMMAND_PACKAGES=()
declare -a INSTALL_RECIPIES=()
for (( i=0; i<${#PACKAGES[@]}; i++ )); do
  package="${PACKAGES[$i]}"
  # If the 'package' exist into the 'rcp' folder it should install from there.
  # Otherwise add the package into the install command packages.
  if [ -e "$RECIPE_DIR/${package}.sh" ]; then
    INSTALL_RECIPIES+=($package)
  else
    INSTALL_COMMAND_PACKAGES+=($package)
  fi
done

# Install from package manager
echo "Execute install command: \"${INSTALL_COMMAND} ${INSTALL_COMMAND_PACKAGES[@]}\"."
eval "sudo ${INSTALL_COMMAND} ${INSTALL_COMMAND_PACKAGES[@]}"

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

