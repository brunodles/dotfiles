# Current Repository State

This document reflects the **actual** structure of the repository as of July 2026.
Auto-audited against `git ls-files` — every file listed is tracked, nothing is guessed.

---

## Directory Overview

```
dotfiles/
├── .gitignore
├── .github/
│   └── copilot-instructions.md
├── .git-queue/
│   └── tasks/
│       ├── TASK-001.json
│       ├── TASK-002.json
│       ├── TASK-003.json
│       ├── TASK-004.json
│       ├── TASK-005.json
│       ├── TASK-006.json
│       └── TASK-007.json
├── LICENSE
├── README.md
│
├── agents/                         # Agent configuration & skill definitions
│   ├── opencode/
│   │   └── instructions.md
│   └── skills/
│       ├── grill-me/
│       │   └── SKILL.md
│       ├── handoff/
│       │   └── SKILL.md
│       └── to-prd/
│           └── SKILL.md
│
├── docs/                           # Documentation
│   ├── agent-queue-design.md
│   ├── current-state.md            # ← this file
│   ├── install-list.md
│   ├── networking.md
│   ├── networking/                 # VPN architecture (WireGuard)
│   │   ├── README.md
│   │   ├── decisions.md
│   │   ├── remote-access.md
│   │   └── vpn.md
│   ├── repository-structure.md
│   ├── stacks.md
│   ├── future/
│   │   ├── agent-queue-feasibility.md
│   │   ├── docs-pipeline.md
│   │   ├── gitea-hermes-infra.md
│   │   ├── gitea-stack-plan.md
│   │   ├── system-env-bootstrap.md
│   │   ├── termux-speech-to-text.md
│   │   └── termux-tts-server.md
│   ├── improvements/
│   │   ├── docs-bootstrap-review.md
│   │   ├── docs-sync-review.md
│   │   └── jekyll-docs-integration-review.md
│   └── router/
│       └── askey-rtf8115vw.md
│
├── dotfiles/                       # Workstation configuration files
│   ├── .vimrc
│   ├── compton.conf
│   ├── alacritty/
│   │   ├── alacritty.toml
│   │   ├── keyboard.toml
│   │   ├── window_linux.toml
│   │   └── window_mac.toml
│   ├── ghostty/
│   │   └── config
│   ├── i3/
│   │   ├── config
│   │   └── openTerminal.sh
│   ├── i3blocks/
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
│   │   └── config
│   ├── tmux/
│   │   └── tmux.conf
│   └── zsh/
│       ├── alias
│       ├── alias_termux
│       ├── env
│       ├── p10k.zsh
│       └── zshrc
│
├── hosts/                          # Host-specific configurations
│   ├── android_server/             # Android/Termux device (always-on server)
│   │   ├── README.md
│   │   ├── bootstrap.sh
│   │   ├── bootstrap/
│   │   │   ├── configure.sh
│   │   │   ├── install.sh
│   │   │   ├── lib.sh
│   │   │   └── links.sh
│   │   ├── dns/
│   │   │   └── dnsmasq.conf
│   │   ├── home/.local/bin/
│   │   │   ├── termux-battery-status
│   │   │   ├── termux-ip
│   │   │   ├── termux-notify
│   │   │   ├── termux-sleep
│   │   │   ├── termux-ssh-tunnel
│   │   │   ├── termux-tts-server
│   │   │   ├── termux-wake
│   │   │   └── tts-bot/               # Telegram → TTS bot app
│   │   │       ├── .env.example
│   │   │       ├── .gitignore
│   │   │       ├── README.md
│   │   │       ├── bot.py
│   │   │       ├── env.py
│   │   │       ├── main.py
│   │   │       └── tts.py
│   │   ├── termux/
│   │   │   └── termux.properties
│   │   └── var/service/              # runit service definitions
│   │       ├── tts-bot/
│   │       │   ├── run
│   │       │   └── log/run
│   │       └── ttsd/
│   │           ├── run
│   │           └── log/run
│   │
│   ├── media/                     # Media server (Ubuntu)
│   │   ├── bootstrap.sh
│   │   └── bootstrap/
│   │       ├── install.sh
│   │       ├── links.sh
│   │       └── provision.sh
│   │
│   ├── phone/                     # Android phone (terminal client)
│   │   ├── README.md
│   │   ├── bootstrap.sh
│   │   ├── bootstrap/
│   │   │   ├── configure.sh
│   │   │   ├── install.sh
│   │   │   └── links.sh
│   │   └── home/.ssh/
│   │       └── config
│   │
│   ├── pi/                        # Raspberry Pi (Pi-hole)
│   │   ├── README.md
│   │   ├── bootstrap.sh
│   │   ├── bootstrap/
│   │   │   ├── configure.sh
│   │   │   ├── install.sh
│   │   │   ├── lib.sh
│   │   │   └── links.sh
│   │   ├── pihole/scripts/
│   │   │   ├── extract-config.sh
│   │   │   └── restore-config.sh
│   │   └── tailscale/
│   │       ├── .env.example
│   │       └── start.sh
│   │
│   ├── silver/                    # Desktop (Ubuntu, silver PC)
│   │   ├── README.md
│   │   ├── bootstrap.sh
│   │   ├── bootstrap/
│   │   │   ├── install.sh
│   │   │   └── links.sh
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
│   │       └── _gr
│   │
│   ├── vps/                       # Internet-facing VPS (Ubuntu)
│   │   ├── bootstrap.sh
│   │   └── bootstrap/
│   │       ├── install.sh
│   │       ├── links.sh
│   │       └── provision.sh
│   │
│   └── work/                      # macOS workstation (work)
│       ├── bootstrap.sh
│       └── bootstrap/
│           ├── configure.sh
│           ├── install.sh
│           └── links.sh
│
├── stacks/                        # Docker stacks — canonical, shared across hosts
│   ├── calibre/                   # Ebook library (linuxserver/calibre-web)
│   │   └── compose.yaml
│   ├── dockge/                    # Dockge UI (louislam/dockge:1)
│   │   └── compose.yaml
│   ├── docs/                      # Documentation site (mkdocs/docsify)
│   │   ├── .env.example
│   │   ├── compose.yaml
│   │   └── sync/
│   │       ├── Dockerfile
│   │       └── sync.py
│   ├── gitea/                     # Gitea on VPS (gitea/gitea:latest)
│   │   └── compose.yml
│   ├── gitea_vps/                 # Gitea on VPS (standalone setup)
│   │   ├── README.md
│   │   ├── compose.yml
│   │   ├── setup.sh
│   │   └── setup/
│   │       ├── .env.example
│   │       └── init.sh
│   ├── hermes/                    # Hermes Agent (nousresearch/hermes-agent)
│   │   ├── .gitconfig
│   │   └── compose.yaml
│   ├── immich/                    # Photo/video management (immich-server)
│   │   ├── .env.example
│   │   ├── README.md
│   │   └── compose.yaml
│   ├── jekyll/                    # Jekyll static site (jekyll/jekyll)
│   │   ├── compose.yaml
│   │   ├── repos.txt
│   │   ├── sync-repos.sh
│   │   └── site/
│   │       ├── _config.yml
│   │       ├── index.md
│   │       └── _layouts/
│   │           └── default.html
│   ├── jellyfin/                  # Media server (linuxserver/jellyfin)
│   │   └── compose.yml
│   ├── metube/                    # YouTube downloader (alexta69/metube)
│   │   └── compose.yml
│   ├── plex/                      # Media server (linuxserver/plex)
│   │   └── docker-compose.yml
│   ├── qbittorrent/               # Torrent client (hotio/qbittorrent)
│   │   └── docker-compose.yml
│   ├── static/                    # Static file server (nginx:alpine)
│   │   └── compose.yaml
│   ├── syncthing/                 # File sync (linuxserver/syncthing)
│   │   └── compose.yml
│   ├── tailscale/                 # Tailscale sidecar (tailscale/tailscale)
│   │   ├── .env.example
│   │   ├── README.md
│   │   └── compose.yaml
│   ├── traefik/                   # Reverse proxy (traefik:v3)
│   │   ├── compose.yaml
│   │   └── config/
│   │       ├── traefik.yml
│   │       ├── acme/
│   │       └── dynamic/
│   ├── vikunja/                   # Task management (vikunja/vikunja)
│   │   ├── .env.example
│   │   ├── compose.yml
│   │   └── vikunja-init.sh
│   ├── wireguard/                 # VPN server (linuxserver/wireguard)
│   │   ├── .env.example
│   │   ├── compose.yaml
│   │   └── setup.sh
│   └── whoami/                    # Test endpoint (traefik/whoami)
│       └── compose.yaml
│
└── scripts/                       # Utility & automation scripts
    ├── git-queue                  # Git queue CLI tool
    ├── git-queue-pre-push         # Pre-push hook
    ├── install-skills.sh          # Agent skill installer
    ├── install_list.sh
    ├── stacks-up                  # Docker Compose orchestrator
    │
    ├── bootstrap/                 # Shared bootstrap helpers
    │   ├── _env.source.sh
    │   ├── _log.source.sh
    │   ├── dockge
    │   ├── docs
    │   ├── env_install
    │   ├── link                   # Safe symlink utility
    │   ├── stacks-up
    │   └── traefik
    │
    ├── dns/                       # Central DNS config & deployment
    │   ├── apply-dns.sh
    │   └── dns-config.example.yaml
    │
    ├── docker/                    # Docker CLI wrappers
    │   ├── claude
    │   ├── copilot
    │   ├── docker-run_or_exec
    │   └── hermes_local
    │
    ├── install/                   # Reusable install scripts (per-OS)
    │   ├── _claudeCode.sh
    │   ├── _fonts.sh
    │   ├── _hermesAgent.sh
    │   ├── _homebrew.sh
    │   ├── _oh-my-zsh.sh
    │   ├── _ollama.sh
    │   ├── _pihole.sh
    │   ├── _samba.post-install.sh
    │   ├── _tailscale.sh
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
    ├── router/                    # Router automation
    │   └── update-dns.sh
    │
    ├── termux/                    # Shared Termux scripts & config
    │   ├── README.md
    │   ├── termux.properties
    │   └── bin/
    │       ├── termux-ip
    │       ├── termux-notify
    │       └── termux-wake
    │
    └── vpn/                       # VPN utilities
        └── sshuttle.sh
```

---

## Host Details

### android_server

| Item | Value |
|------|-------|
| Location | Home LAN |
| OS | Android + Termux |
| Package manager | `pkg` |
| Service manager | `termux-services` (runit/sv) |
| Shell | Zsh + Oh My Zsh + Powerlevel10k |
| SSH port | 8022 |
| Connectivity | Wi-Fi + Tailscale |
| Purpose | Always-on Android server (SSH tunnel, tailnet node, TTS bot) |
| DNS role | Secondary DNS (Dnsmasq) |
| TTS bot | Telegram → Termux TTS via `tts-bot/main.py` |
| Services | `sshd`, `ttsd`, `tts-bot` (runit supervised) |

### phone

| Item | Value |
|------|-------|
| Location | Mobile (Wi-Fi + 4G/5G) |
| OS | Android + Termux |
| Package manager | `pkg` |
| Shell | Zsh + Oh My Zsh |
| Connectivity | Tailscale only (no fixed IP, no DHCP reservation) |
| Purpose | Terminal client — SSH into homelab hosts |
| Services | None (consumer device, no daemons) |
| Scripts | Shared via `scripts/termux/` |
| SSH | Client only — no sshd |

### media

| Item | Value |
|------|-------|
| Location | Home LAN |
| OS | Ubuntu |
| Connectivity | Wired Ethernet + Tailscale |
| Stacks | dockge, gitea, immich, jellyfin, metube, plex, qbittorrent, syncthing, traefik, whoami |
| Symlinked via | `provision.sh` → `/dockge/stacks/<name>/` |

### pi

| Item | Value |
|------|-------|
| Location | Home LAN |
| OS | Raspberry Pi OS (Debian-based) |
| Connectivity | Wired Ethernet + Tailscale |
| Services | Pi-hole (DNS sinkhole, local DNS) |
| DNS role | Primary DNS for the tailnet |
| DNS records | Local records via `/etc/dnsmasq.d/` from `scripts/dns/dns-config.yaml` |
| Status | Placeholder — Pi not yet on the same network |

### silver

| Item | Value |
|------|-------|
| Location | Home LAN |
| OS | Ubuntu |
| Shell | Zsh + Oh My Zsh |
| Connectivity | Wired Ethernet + Tailscale |
| Desktop | HyperLand (primary), i3wm (legacy) |
| Custom scripts | Network, wallpaper, terminal, Ollama, font management |
| Note | Does not run Docker stacks — workstation only |

### vps

| Item | Value |
|------|-------|
| Location | Cloud (public IP) |
| OS | Ubuntu (server) |
| Connectivity | Public internet + WireGuard |
| Proxy | Traefik v3 (Docker provider + file provider) |
| SSL | Let's Encrypt (ACME) |
| Stacks | dockge, gitea, hermes, traefik, wireguard |
| Docker network | `proxy` (external, shared) |

### work

| Item | Value |
|------|-------|
| Location | Remote (workplace) |
| OS | macOS |
| Shell | Zsh + Oh My Zsh |
| Connectivity | WireGuard |

---

## Stack Architecture

All Docker stacks live at `stacks/<name>/` in the repo root —
**canonical source of truth**, shared across all hosts.

### Runtime layout per host

```
/dockge/
└── stacks/
    ├── dockge/    → <repo>/stacks/dockge/   ← Dockge manages itself
    ├── gitea/     → <repo>/stacks/gitea/
    ├── traefik/   → <repo>/stacks/traefik/
    └── ...        ← only stacks the host needs
```

Each host's bootstrap creates `/dockge/stacks/` and symlinks the stacks
it needs. Per-host `.env` files (domains, volume paths) are created
during bootstrap, sourced from the (private) `secrets/` repo.

### Key Docker images

| Stack | Image | Port | Notes |
|-------|-------|------|-------|
| calibre | linuxserver/calibre-web | — | eBook library |
| dockge | louislam/dockge:1 | 5001 | Stack manager UI |
| gitea | gitea/gitea | 3000 | Git server (SQLite) |
| hermes | nousresearch/hermes-agent | — | AI agent |
| immich | ghcr.io/immich-app/immich-server | 2283 | Photo/video mgmt |
| jellyfin | linuxserver/jellyfin | 8096 | Media server |
| metube | alexta69/metube | 8081 | YouTube downloader |
| plex | linuxserver/plex | 32400 | Media server |
| qbittorrent | hotio/qbittorrent | 8080 | Torrent client |
| syncthing | linuxserver/syncthing | 8384 | File sync |
| traefik | traefik:v3 | 80, 443 | Reverse proxy |
| vikunja | vikunja/vikunja | 3456 | Task management |
| whoami | traefik/whoami | — | Test endpoint |

---

## Notes

- **228 tracked files** across all sections.
- **No untracked files, no deleted files.** Working tree is clean.
- All install scripts live under `scripts/install/` — no top-level `install/` directory.
- `scripts/bootstrap/` contains shared helpers used by host bootstrap scripts.
- `scripts/docker/` contains Docker CLI wrappers (Claude, Copilot, Hermes).
- `scripts/dns/` feeds all hosts from a single `dns-config.{yaml,example.yaml}`.
- `scripts/termux/` contains scripts shared between `android_server` and `phone`.
- `agents/skills/` defines agent skills (grill-me, handoff, to-prd).
- `.git-queue/` is the coordination system for multi-agent edits. See `docs/agent-queue-design.md`.
- `docs/future/` contains pre-feasibility research. Not implementation specs.
- `docs/improvements/` contains past review feedback docs.
- `docs/networking/` contains VPN architecture (WireGuard), setup, and ADR decisions.
- **`stacks/vikunja/`**, **`stacks/gitea_vps/`**, and **`stacks/wireguard/`** are new — single-image stacks with init scripts.
- The `phone` host is the only consumer-only device: no services, no daemons, no DNS role.
