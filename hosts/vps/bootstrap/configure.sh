#!/usr/bin/env bash
# configure.sh — Configure VPS: stack symlinks, Docker network, workspace
source "$HOME/dotfiles/scripts/bootstrap/_log.source.sh"
source "$HOME/dotfiles/scripts/bootstrap/_env.source.sh"

$BOOTSTRAP_DIR/dockge gitea hermes tailscale traefik
$BOOTSTRAP_DIR/traefik
