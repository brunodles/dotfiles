# Bruno's Global Copilot Instructions

## Language

- Code, comments, and documentation in English only.
- Portuguese is for conversation only.

## Code conventions

- Prefer `uv` over pip. Prefer `just` over Make.
- All scripts must be idempotent. Silent success, errors only on failure.
- Bash: `set -euo pipefail`, trap ERR, use SCRIPT_DIR for paths.
- Docker Compose: named volumes, Traefik labels for routing.
- Python: 4-space indentation, type hints on public functions.
- YAML/Dockerfile: 2-space indentation.

## Git

- Conventional commits: feat:, fix:, docs:, chore:, refactor:.
- One logical change per commit. English commit messages.
- After each commit, run a review against the original plan.

## Infrastructure

- 6 homelab hosts: vps (Docker stacks), pi (Pi-hole + Tailscale),
  silver (desktop), media, android (Termux), work (dev workstation).
- Tailscale for connectivity, Pi-hole for DNS, Traefik for reverse proxy.
- dotfiles repo is the source of truth for all config.
