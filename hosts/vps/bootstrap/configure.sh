#!/usr/bin/env bash
# configure.sh — Configure VPS: stack symlinks, Docker network, workspace
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

REPO_ROOT="$(cd "$HOST_DIR/../.." && pwd)"
STACKS_SRC="$REPO_ROOT/stacks"

info "Setting up /dockge/ stack symlinks..."
sudo mkdir -p /dockge/stacks

# Link stacks this host needs
for stack in dockge gitea hermes tailscale traefik; do
  if [[ -d "$STACKS_SRC/$stack" ]]; then
    sudo ln -sf "$STACKS_SRC/$stack" "/dockge/stacks/$stack"
    info "  linked stacks/$stack"
  else
    warn "  stacks/$stack not found — skipping"
  fi
done

# Ensure Dockge data dir exists
sudo mkdir -p /dockge/stacks/dockge/data

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
