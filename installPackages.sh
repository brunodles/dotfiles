#!/bin/bash
#installPackages

where() {
	echo $(command -v $1)
}

install() {
	if [ ! -z "$(where pacman)" ]; then
		pacman -S $@
	elif [ ! -z "$(where apt)" ]; then
		apt install $@	
	elif [ ! -z "$(where brew)" ]; then
		brew install $@	
        else
		echo $@
	fi
}

tools=(
	# build tools
	base-devel
	# common tools
	vim curl git
	# browser
	firefox
	# terminal emulator, prompt and multiplexer
	alacritty
	tmux
	zsh
	# oh-my-zsh - is a custom script
	# background, transparency support
	feh compton

)
echo "This script will install: \"${tools[@]}\"."
read -p ":: Continue install? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

install ${tools[@]}

