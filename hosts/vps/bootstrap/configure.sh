#!/usr/bin/env bash
# configure.sh — Configure VPS: Dockge symlinks, Docker network, workspace
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

dockge_path="$HOST_DIR/dockge"

info "Setting up Dockge symlinks..."
sudo mkdir -p /opt
sudo ln -sf "$dockge_path/stacks" /opt/stacks
sudo ln -sf "$dockge_path/dockge" /opt/self
sudo chown "$USER" "$dockge_path/stacks"
sudo chown "$USER" "$dockge_path/dockge"

info "Creating Docker proxy network for Traefik..."
if docker network ls --format '{{.Name}}' | grep -q '^proxy$'; then
  info "  proxy network already exists"
else
  sudo docker network create proxy
  info "  proxy network created"
fi

info "Creating workspace..."
mkdir -p "$HOME/workspace"

info "Configure complete — run links.sh"
