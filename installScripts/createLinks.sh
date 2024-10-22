#!/bin/bash
# This script will create symbolic links between configuration files
# (under ~/.config) and their expected place at home (~).
# With this kind of link we can keep all the configurations under the same folder/repo.

# Link ~/.zshrc
mkdir -p ~/.config/backup/
cp ~/.zshrc ~/.config/backup/
rm ~/.zshrc
ln -s ~/.config/zsh/zshrc ~/.zshrc

