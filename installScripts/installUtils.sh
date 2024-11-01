#!/bin/bash
# Utility for installing packages in linux and ubuntu.
# The functions in this document will be used by another script.
# Author: Bruno de Lima <github.com/brunodles>

# These are constants
declare DOTFILE_REPOS=~/dotfiles/repos

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


executeInstall() {
	declare uname=$(uname)
	declare -a tools=()
	tools+=()
	case "$uname" in
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


	case "$uname" in
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
			if [[ ! -z "${_brew[@]}" ]]; then
			  local installCommand="brew install ${_brew[@]}"
			  echo "$installCommand"
			  sh -c "$installCommand"
			fi
			if [[ ! -z "${_brew_cask[@]}" ]]; then 
			  local installCommand="brew install --cask ${_brew_cask[@]}"
			  echo "$installCommand"
			  sh -c "$installCommand"
			fi
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
		curl -o /tmp/docker-desktop-amd64.deb https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb
		sudo apt-get update
		sudo apt-get install /tmp/docker-desktop-amd64.deb
		#rm -f /tmp/docker-desktop-amd64.deb
	fi
}
 
