#!/bin/bash

tmux_location=$(command -v tmux)
if [[ -z "$tmux_location" ]];then 
  echo "Tmux is not installed"
  return 1
fi

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

