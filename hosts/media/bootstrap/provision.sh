#!/usr/bin/env bash
# provision.sh — Provision media server: env, stacks, Docker network
BOOTSTRAP_DIR="$HOME/dotfiles/scripts/bootstrap/"

$BOOTSTRAP_DIR/env_install
$BOOTSTRAP_DIR/dockge traefik gitea jellyfin metube syncthing
$BOOTSTRAP_DIR/traefik

