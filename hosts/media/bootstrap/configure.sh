#!/usr/bin/env bash
# configure.sh — Configure media server settings
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

info "Creating Docker proxy network for Traefik..."
if docker network ls --format '{{.Name}}' | grep -q '^proxy$'; then
  info "  proxy network already exists"
else
  sudo docker network create proxy
  info "  proxy network created"
fi

info "Media configure complete — run links.sh next"
