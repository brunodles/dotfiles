#!/usr/bin/env bash
# configure.sh — Configure Pi-hole settings
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# ── Restore saved Pi-hole config ───────────────────────────────
info "Restoring Pi-hole configuration..."
restore_script="$HOST_DIR/pihole/scripts/restore-config.sh"
if [[ -f "$restore_script" ]]; then
  bash "$restore_script"
else
  warn "  restore-config.sh not found. Run it later from the repo."
fi

info ""
info "Next steps:"
info "  1. Set Pi-hole web password:  pihole -a -p"
info "  2. Access admin panel:  http://<pi-ip>/admin"
