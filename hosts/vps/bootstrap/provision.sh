#!/usr/bin/env bash
# provision.sh — Provision VPS: env, stack symlinks, Docker network, workspace
source "$HOME/dotfiles/scripts/bootstrap/_log.source.sh"
source "$HOME/dotfiles/scripts/bootstrap/_env.source.sh"

# install system-wide env vars for docker compose
$SCRIPT_BOOTSTRAP_DIR/env_install
# generate .env files with auto-generated secrets for stacks that need them
$SCRIPT_BOOTSTRAP_DIR/password
$SCRIPT_BOOTSTRAP_DIR/dockge calibre docs gitea_vps hermes jekyll static tailscale traefik vikunja
$SCRIPT_BOOTSTRAP_DIR/docs
$SCRIPT_BOOTSTRAP_DIR/traefik
