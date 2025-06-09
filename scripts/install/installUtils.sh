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

# Install Alacritty
# Build from source is required for alacritty because the package systems are not consistent.
# They don't have the same version available.
# Build alacritty from source in a docker image. Compilation happens inside a docker container.
# https://github.com/mdedonno1337/docker-alacritty
installAlacritty() {
	echo Install Alacritty
	mkdir -p $DOTFILE_REPOS
	cd $DOTFILE_REPOS
	git clone git@github.com:mdedonno1337/docker-alacritty.git
	cd docker-alacritty
	make
	sudo mv alacritty /usr/bin
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
			#if [ -z "$(where docker)" ] || [ -z "$(where docker-compose)" ]; then
			#	tools+=(docker docker-compose)
			#fi
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
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)
		# install zsh-autosuggestions
		git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
		git clone https://github.com/zsh-users/zsh-completions.git ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
		git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
                git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
	fi

	# Docker, DockerCompose
	# Install using the suggested scripts at docker page.
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

	# Alacritty
	if [[ " ${tools[*]} " == *" alacritty "* ]]; then
		installAlacritty
	fi

	# tmux
	if [[ " ${tools[*]} " == *" tmux "* ]]; then
	  install tmux
	  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
	fi

	 
}
 
