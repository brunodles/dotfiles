# Bruno's Global OpenCode Instructions

## Language

- English for all code, comments, commit messages, and documentation.
- Portuguese only for conversation with the user.

## Workflow

- Read the project's CLAUDE.md at root before starting work.
- Make one logical change at a time. Commit after each.
- Commit format: `type(scope): concise description`.
- After each commit, review the diff against the original plan.

## Conventions

- Idempotent scripts — safe to run multiple times.
- Silent by default. Only print on warnings, errors, or when explicitly asked.
- Bash: `set -euo pipefail`, use SCRIPT_DIR for portable paths.
- Python: `uv` preferred, type hints on all public APIs.
- Docker Compose: Traefik-compatible labels, named volumes.
- Indentation: 2-space for YAML/Dockerfile, 4-space for Python.

## Context

- This is a homelab dotfiles repository managing 6 hosts:
  vps, pi, silver, media, android, work.
- Tailsecures the network. Pi-hole for DNS. Traefik in front of web services.
- Every host has a bootstrap directory in hosts/<name>/bootstrap/ that sets it up from scratch.
