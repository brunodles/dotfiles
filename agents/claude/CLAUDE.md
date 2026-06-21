# Bruno's Global Claude Config

## About the user

- Native Portuguese speaker; code, comments, and documentation in English.
- Manages a homelab with 6 hosts (vps, pi, silver, media, android, work).
- Uses Tailscale for connectivity, Pi-hole for DNS, Traefik for reverse proxy.
- dotfiles repo lives at ~/dotfiles — that's the canonical source of truth.

## Code & conventions

- Python 3.13+, TypeScript, bash, Docker Compose, Terraform/HCL.
- Prefers `uv` over pip. Prefers `just` over Make where possible.
- All scripts must be idempotent. Check before create.
- Silent success — no echo for expected outcomes. Errors only.
- tab = 2 spaces for YAML/Docker, 4 spaces for Python.
- Use `set -euo pipefail` in bash scripts. Trap ERR for cleanup.

## Git

- One logical change per commit.
- Commit messages in English. Conventional commits format
  (feat:, fix:, docs:, chore:, refactor:).
- After each commit, a subagent reviews the diff against the plan.

## This file

This is the **global** CLAUDE.md — it applies to every project.
For project-specific instructions, see each repo's own CLAUDE.md.

## Git Queue Protocol

When working on the dotfiles repo (`~/dotfiles`), use the queue-based
coordination system:
1. `cd ~/dotfiles && scripts/git-queue acquire`
2. Set `export GIT_QUEUE_AGENT=claude GIT_QUEUE_TASK=<id>`
3. Make changes, commit, push
4. `scripts/git-queue release`

See `docs/agent-queue-design.md` for details.
