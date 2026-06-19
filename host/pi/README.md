# Pi — Raspberry Pi (Pi-hole)

Raspberry Pi running Pi-hole for DNS-level ad blocking on the homelab network.

## Status

The Pi is not yet on the same network. Configuration will be extracted
once it becomes reachable via SSH.

## Services

- **Pi-hole** — DNS sinkhole (blocklist-based ad blocking)
- **DNS** — Local DNS resolution for homelab services

## Extraction

Run `pihole/scripts/extract-config.sh <user>@<pi-ip>` to pull the current
configuration into `pihole/extracted/`.

## Restore

Run `pihole/scripts/restore-config.sh` on a fresh Pi-hole install to
reapply all DNS settings, blocklists, whitelists, and custom rules.
