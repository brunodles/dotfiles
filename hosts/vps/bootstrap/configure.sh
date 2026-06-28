#!/usr/bin/env bash
# configure.sh — Configure VPS: env, stack symlinks, Docker network, workspace
source "$HOME/dotfiles/scripts/bootstrap/_log.source.sh"
source "$HOME/dotfiles/scripts/bootstrap/_env.source.sh"

# install system-wide env vars for docker compose
$SCRIPT_BOOTSTRAP_DIR/env_install
$SCRIPT_BOOTSTRAP_DIR/dockge calibre gitea_vps hermes jekyll static tailscale traefik
$SCRIPT_BOOTSTRAP_DIR/traefik

