#!/usr/bin/env bash
# Setup common environment variables
# This still relevant as this lib would be imported during the install phase
# where the `.env` might not be installed.
# This file should be imported on other scripts

#HOME = /home/<user>
REPO_DIR="$HOME/dotfiles"
SCRIPT_DIR="$REPO_DIR/scripts"
SCRIPT_BOOTSTRAP_DIR="$REPO_DIR/scripts/bootstrap"
SCRIPT_INSTALL_DIR="$REPO_DIR/scripts/install"
STACKS_SRC_DIR="$REPO_DIR/stacks"
DOCKGE_OUT_DIR="$HOME/dockge"
DOCKGE_DOCKGE_OUT_DIR="$DOCKGE_OUT_DIR/dockge"
STACKS_OUT_DIR="$DOCKGE_OUT_DIR/stacks"
