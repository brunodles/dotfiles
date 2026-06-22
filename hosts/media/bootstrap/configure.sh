#!/usr/bin/env bash
# configure.sh — Configure media server: stack symlinks, Docker network
BOOTSTRAP_DIR="$HOME/dotfiles/scripts/bootstrap/"

$BOOTSTRAP_DIR/dockge traefik gitea jellyfin metube syncthing
$BOOTSTRAP_DIR/traefik

