# Setup common environment variables
# This still relevant as this lib would be imported during the install phase
# where the `.env` might not be installed.
# This file should be imported on other scripts

# Setup environment variables
#HOME=/home/<user>
export REPO_DIR="$HOME/dotfiles"

export SCRIPT_DIR="$REPO_DIR/scripts"
export SCRIPT_BOOTSTRAP_DIR="$REPO_DIR/scripts/bootstrap"
export SCRIPT_INSTALL_DIR="$REPO_DIR/scripts/install"
export STACKS_SRC_DIR="$REPO_DIR/stacks"

export DOCKGE_OUT_DIR="/dockge"
export DOCKGE_DOCKGE_OUT_DIR="$DOCKGE_OUT_DIR/dockge"
export STACKS_OUT_DIR="$DOCKGE_OUT_DIR/stacks"

# Make their dir
sudo mkdir -p $DOCKGE_OUT_DIR
sudo chown $USER $DOCKGE_OUT_DIR
mkdir -p $DOCKGE_DOCKGE_OUT_DIR
mkdir -p $STACKS_OUT_DIR
