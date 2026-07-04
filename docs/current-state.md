# Current Repository State

This document reflects the **actual** structure of the repository as of June 2026.
It is auto-audited against the filesystem to ensure accuracy.

---

## Directory Overview

```
dotfiles/
├── README.md
├── LICENSE
├── .gitignore
│
├── .github/
│   └── copilot-instructions.md
├── .git-queue/                         # Git queue task coordination
│   └── tasks/
│       ├── TASK-001.json
│       ├── TASK-002.json
│       ├── TASK-003.json
│       ├── TASK-004.json
│       ├── TASK-005.json
│       ├── TASK-006.json
│       └── TASK-007.json
├── CLAUDE.md                           # Agent coordination instructions
├── agents/                             # Agent configuration files
│   ├── claude/
│   │   ├── CLAUDE.md
│   │   └── rules/
│   ├── copilot/
│   │   └── instructions.md
│   ├── hermes/
│   │   └── soul.md
│   ├── opencode/
│   │   └── instructions.md
│   └── skills/                         # Skill definitions (regenerated)
│
├── docs/
│   ├── agent-queue-design.md               # Git queue coordination design
│   ├── current-state.md                     # ← this file
│   ├── install-list.md                      # Package DSL documentation
│   ├── networking.md                        # Network topology & connectivity
│   ├── repository-structure.md              # Aspirational layout
│   ├── stacks.md                            # Docker stacks overview
│   ├── future/
│   │   ├── agent-queue-feasibility.md       # Queue feasibility study
│   │   ├── gitea-hermes-infra.md            # Gitea for Hermes analysis
│   │   └── gitea-stack-plan.md              # Gitea production readiness plan
│   └── router/
│       └── askey-rtf8115vw.md               # Router DNS API guide
│
├── dotfiles/                  # Workstation configuration files
│   ├── .vimrc
│   ├── compton.conf
│   ├── alacritty/
│   │   ├── alacritty                    # symlink to self (macOS)
│   │   ├── alacritty.toml
│   │   ├── keyboard.toml
│   │   ├── window_linux.toml
│   │   └── window_mac.toml
│   ├── ghostty/
│   │   ├── config
│   │   └── ghostty                      # symlink to self (macOS)
│   ├── i3/
│   │   ├── config
│   │   ├── i3                           # symlink to self
│   │   └── openTerminal.sh
│   ├── i3blocks/
│   │   ├── i3blocks                     # symlink to self
│   │   ├── title.conf
│   │   ├── top.conf
│   │   └── scripts/
│   │       ├── batery
│   │       ├── i3wsbar
│   │       ├── markup
│   │       ├── temperature
│   │       ├── title
│   │       ├── titlebar
│   │       └── volume
│   ├── i3status/
│   │   ├── config
│   │   └── i3status                     # symlink to self
│   ├── tmux/
│   │   └── tmux.conf
│   └── zsh/
│       ├── alias
│       ├── env
│       ├── p10k.zsh
│       ├── zsh                          # symlink to self
│       └── zshrc
│
├── stacks/                    # Docker stacks — canonical, reusable per host
│   ├── calibre/               # Ebook library web UI (linuxserver/calibre-web)
│   │   ├── compose.yaml
│   │   ├── config/
│   │   │   └── .gitkeep
│   │   └── books/
│   │       └── .gitkeep
│   ├── dockge/                # Dockge UI (louislam/dockge:1)
│   │   ├── .gitignore         # ignores data/*
│   │   └── compose.yaml       # mounts ../:/opt/stacks, Traefik-labeled
│   ├── gitea/                 # Gitea + SQLite (gitea/gitea:1.22.4)
│   │   ├── .env.example
│   │   ├── README.md
│   │   ├── compose.yml
│   │   └── config/
│   │       └── .keep
│   ├── hermes/                # Hermes Agent (nousresearch/hermes-agent:latest)
│   │   ├── .gitconfig
│   │   └── compose.yaml
│   ├── immich/                # Photo/video management (ghcr.io/immich-app/immich-server)
│   │   ├── compose.yaml
│   │   ├── .env.example
│   │   ├── config/
│   │   │   └── .gitkeep
│   ├── jekyll/                # Jekyll static site server (jekyll/jekyll:latest)
│   │   ├── compose.yaml
│   │   └── site/
│   │       └── .gitkeep
│   ├── jellyfin/              # Media server (linuxserver/jellyfin:10.10.7)
│   │   └── compose.yml
│   ├── metube/                # YouTube downloader (ghcr.io/alexta69/metube)
│   │   └── compose.yml
│   ├── plex/                  # Media server (lscr.io/linuxserver/plex:1.40.5)
│   │   └── docker-compose.yml
│   ├── qbittorrent/           # Torrent client (hotio/qbittorrent:release-5.0.1)
│   │   └── docker-compose.yml
│   ├── static/                # Static file server (nginx:alpine)
│   │   ├── compose.yaml
│   │   └── html/
│   │       └── .gitkeep
│   ├── syncthing/             # File sync (linuxserver/syncthing:1.29.2)
│   │   └── compose.yml
│   ├── tailscale/             # Tailscale sidecar (tailscale/tailscale)
│   │   ├── .env.example
│   │   ├── README.md
│   │   ├── compose.yaml
│   │   └── config/
│   │       └── .keep
│   ├── traefik/               # Reverse proxy (traefik:v3.7)
│   │   ├── compose.yaml
│   │   └── config/
│   │       ├── traefik.yml
│   │       ├── acme/
│   │       │   └── .keep
│   │       └── dynamic/
│   │           └── .keep
│   └── whoami/                # Test endpoint (traefik/whoami)
│       └── compose.yaml
│
├── hosts/                     # Host-specific configurations
│   ├── android/               # Android/Termux device (always-on server)
│   │   ├── README.md
│   │   ├── bootstrap.sh            # → bootstrap/{install,configure,links}.sh
│   │   ├── bootstrap/
│   │   │   ├── install.sh
│   │   │   ├── configure.sh
│   │   │   ├── links.sh
│   │   │   └── lib.sh
│   │   ├── dns/
│   │   │   └── unbound.conf
│   │   ├── home/.local/bin/
│   │   │   ├── termux-battery-status
│   │   │   ├── termux-ip
│   │   │   ├── termux-notify
│   │   │   ├── termux-sleep
│   │   │   ├── termux-ssh-tunnel
│   │   │   └── termux-wake
│   │   └── termux/
│   │       └── termux.properties
│   │
│   ├── media/                 # Media server
│   │   ├── bootstrap.sh
│   │   └── bootstrap/
│   │       ├── install.sh
│   │       ├── configure.sh       # symlinks stacks/ for this host
│   │       ├── links.sh
│   │       └── lib.sh
│   │
│   ├── pi/                    # Raspberry Pi (Pi-hole)
│   │   ├── README.md
│   │   ├── bootstrap.sh
│   │   ├── bootstrap/
│   │   │   ├── install.sh
│   │   │   ├── configure.sh
│   │   │   ├── links.sh
│   │   │   └── lib.sh
│   │   ├── pihole/
│   │   │   ├── extracted/     # future: exported configs
│   │   │   │   └── .keep
│   │   │   └── scripts/
│   │   │       ├── extract-config.sh   # SSH-based config pull
│   │   │       └── restore-config.sh   # apply saved config locally
│   │   └── tailscale/
│   │       ├── .env.example
│   │       └── start.sh
│   │
│   ├── silver/                # Desktop (Ubuntu, silver PC)
│   │   ├── README.md
│   │   ├── bootstrap.sh
│   │   ├── bootstrap/
│   │   │   ├── install.sh
│   │   │   ├── links.sh
│   │   │   └── lib.sh
│   │   ├── home/.local/bin/
│   │   │   ├── font_install.sh
│   │   │   ├── font_list.sh
│   │   │   ├── formatAsJson.py
│   │   │   ├── gr
│   │   │   ├── network_interface.sh
│   │   │   ├── ollama
│   │   │   ├── terminal_colors.sh
│   │   │   ├── tmux-android
│   │   │   ├── tmux-sample
│   │   │   └── wallpaper_dynamic.sh
│   │   └── home/.local/fbin/
│   │       └── _gr                       # Zsh completion for `gr`
│   │
│   ├── vps/                   # Internet-facing VPS
│   │   ├── bootstrap.sh
│   │   └── bootstrap/
│   │       ├── install.sh
│   │       ├── configure.sh       # symlinks stacks/ for this host
│   │       ├── links.sh
│   │       └── lib.sh
│   │
│   └── work/                  # macOS workstation (work)
│       ├── README.md
│       ├── bootstrap.sh
│       └── bootstrap/
│           ├── install.sh
│           ├── configure.sh
│           ├── links.sh
│           └── lib.sh
│
├── install/                   # Install scripts (called by bootstrap.sh)
│   ├── _claudeCode.sh
│   ├── _fonts.sh
│   ├── _hermesAgent.sh
│   ├── _homebrew.sh              # macOS Homebrew installer
│   ├── _oh-my-zsh.sh
│   ├── _ollama.sh
│   ├── _pihole.sh             # Pi-hole installer wrapper
│   ├── _samba.post-install.sh
│   ├── _tailscale.sh          # Tailscale (Linux + Termux)
│   ├── _tmux.post-install.sh
│   ├── _xiaomi_mimo.sh
│   ├── arch/
│   │   ├── bootstrap.sh
│   │   ├── filesystem.sh
│   │   ├── jdk8.sh
│   │   └── podman.sh
│   ├── docker/
│   │   └── alacritty.sh
│   └── ubuntu/
│       ├── bootstrap.sh
│       ├── docker.sh
│       ├── filesystem.sh
│       ├── hyperland.sh
│       ├── i3wm.sh
│       ├── nvidia.sh
│       ├── snap.sh
│       └── ufw.sh
│
└── scripts/                   # Utility scripts
    ├── dns/                       # Central DNS config & deployment
    │   ├── dns-config.yaml
    │   └── apply-dns.sh
    ├── docker_claude/
    │   └── claude
    ├── docker_copilot_cli/
    │   └── copilot
    ├── docker_hermes/
    │   └── hermes_local
    ├── docker_run_or_exec/
    │   └── docker-run_or_exec
    ├── git-queue                 # Git queue CLI tool
    ├── git-queue-pre-push        # Pre-push hook script
    ├── install/
    │   └── link
    ├── install-skills.sh       # Agent skill installer
    ├── install_list.sh
    ├── router/
    │   └── update-dns.sh       # Askey router DNS updater
    ├── stacks-up               # Docker Compose orchestrator
    └── vpn/
        └── sshuttle.sh         # Temporary SSH VPN tunnel
```

---

## Host Details

### android

| Item | Value |
|------|-------|
| Location | Home LAN |
| OS | Android + Termux |
| Package manager | `pkg` |
| Service manager | `termux-services` (runit/sv) |
| Shell | Zsh + Oh My Zsh + Powerlevel10k |
| SSH port | 8022 |
| Connectivity | Wi-Fi + Tailscale |
| Purpose | Always-on Android server (SSH tunnel, tailnet node) |
| DNS role | Secondary DNS (Dnsmasq) — fallback to Cloudflare when Pi-hole is unreachable |
| DNS config | Auto-generated from `scripts/dns/dns-config.yaml` via `apply-dns.sh` |

### media

| Item | Value |
|------|-------|
| Location | Home LAN |
| OS | Ubuntu |
| Connectivity | Wired Ethernet + Tailscale |
| Stacks | dockge, gitea, immich, jellyfin, metube, plex, qbittorrent, syncthing, traefik, whoami |
| Symlinked via | `configure.sh` → `/dockge/stacks/<name>/` |

### pi

| Item | Value |
|------|-------|
| Location | Home LAN |
| OS | Raspberry Pi OS (Debian-based) |
| Connectivity | Wired Ethernet + Tailscale |
| Services | Pi-hole (DNS sinkhole, local DNS) |
| DNS role | Primary DNS for the tailnet |
| DNS records | Local records (hosts, CNAMEs) injected via `/etc/dnsmasq.d/99-homelab.conf` from `scripts/dns/dns-config.yaml` |
| Status | Placeholder — Pi not yet on the same network |
| Scripts | `extract-config.sh` (SSH pull), `restore-config.sh` (local apply) |

### silver

| Item | Value |
|------|-------|
| Location | Home LAN |
| OS | Ubuntu |
| Desktop | HyperLand (primary), i3wm (legacy) |
| Shell | Zsh + Oh My Zsh |
| Connectivity | Wired Ethernet + Tailscale |
| Custom scripts | Network, wallpaper, terminal, Ollama, font management |

### vps

| Item | Value |
|------|-------|
| Location | Cloud (public IP) |
| OS | Ubuntu (server) |
| Connectivity | Public internet + Tailscale |
| Proxy | Traefik v3 (Docker provider + file provider) |
| SSL | Let's Encrypt (ACME) |
| Stacks | dockge, gitea, hermes, tailscale, traefik |
| Hermes | Docker container, git identity mounted from stack |
| Symlinked via | `configure.sh` → `/dockge/stacks/<name>/` |
| Docker network | `proxy` (external, shared across stacks) |

### work

| Item | Value |
|------|-------|
| Location | Remote (workplace) |
| OS | macOS |
| Shell | Zsh + Oh My Zsh |
| Connectivity | Tailscale |

---

## Stack Architecture

All Docker stacks live at `stacks/<name>/` in the repo root —
**canonical source of truth**, shared across all hosts.

### Runtime layout per host

```
/dockge/
└── stacks/                    ← DOCKGE_STACKS_DIR=/opt/stacks
    ├── dockge/    → <repo>/stacks/dockge/   ← Dockge manages itself
    ├── gitea/     → <repo>/stacks/gitea/
    ├── traefik/   → <repo>/stacks/traefik/
    └── ...        ← only stacks the host needs
```

Each host's `configure.sh` creates `/dockge/stacks/` and symlinks only the stacks
it needs. Stacks that need per-host customization (domains, volume paths) use
`.env` files created during bootstrap.

---

## Notes

- **`install/`** contains reusable install scripts. Each host's bootstrap scripts under `bootstrap/install.sh` reference them by path.
- **All hosts except silver** follow a `bootstrap.sh` → `bootstrap/{install,configure,links,lib}.sh` pattern (silver omits `configure.sh`). Run `bash hosts/<name>/bootstrap.sh` for the full setup.
- **`scripts/`** contains Docker wrappers (Claude, Copilot CLI, Hermes), the `link` utility for symlinks, the git-queue CLI tool, plus VPN (`vpn/sshuttle.sh`), router DNS (`router/update-dns.sh`), stack orchestration (`stacks-up`), and agent skill installer (`install-skills.sh`).
- **`stacks-up`** auto-detects `stacks/` at repo root; falls back to legacy `hosts/*/dockge/` layout. Accepts explicit args like `stacks/` or `/dockge/stacks/`.
- **`dotfiles/`** only covers config files currently in active use.
- **`projects/`**, **`bootstrap/`**, and backup/restore scripts do not exist yet.
- **`.git-queue/`** is the coordination system for multi-agent edits. See `docs/agent-queue-design.md` and `CLAUDE.md`.
- **Docs** are evolving: `networking.md`, `repository-structure.md`, `stacks.md`, `agent-queue-design.md`, `install-list.md`, and `router/askey-rtf8115vw.md` exist alongside this file.
- **`docs/future/`** contains pre-feasibility research for infrastructure projects (Gitea, queue, etc.). These are not implementation specs — they inform future decisions.
