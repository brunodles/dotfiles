# Current Repository State

This document reflects the **actual** structure of the repository as of June 2026.
It is meant to be a snapshot of reality — not an aspirational layout.

---

## Directory Overview

```
dotfiles/
├── README.md
├── LICENSE
├── .gitignore
│
├── docs/
│   ├── current-state.md                     # ← this file
│   ├── networking.md                        # network topology & connectivity
│   └── repository-structure.md              # aspirational layout
│
├── dotfiles/                  # Workstation configuration files
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
│   │   ├── .gitignore
│   │   └── tmux.conf
│   └── zsh/
│       ├── alias
│       ├── env
│       ├── p10k.zsh
│       └── zshrc
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
│   │   ├── bootstrap/
│   │   │   ├── install.sh
│   │   │   ├── configure.sh
│   │   │   ├── links.sh
│   │   │   └── lib.sh
│   │   └── dockge/
│   │       ├── dockge/
│   │       │   └── compose.yaml
│   │       └── stacks/
│   │           ├── gitea/
│   │           ├── jellyfin/
│   │           ├── metube/
│   │           ├── plex/
│   │           ├── qbittorrent/
│   │           ├── syncthing/
│   │           ├── traefik/
│   │           │   ├── compose.yaml
│   │           │   └── config/traefik.yaml
│   │           └── whoami/
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
│   │   └── home/.local/bin/
│   │       ├── font_install.sh
│   │       ├── font_list.sh
│   │       ├── formatAsJson.py
│   │       ├── gr
│   │       ├── network_interface.sh
│   │       ├── ollama
│   │       ├── terminal_colors.sh
│   │       ├── tmux-android
│   │       ├── tmux-sample
│   │       └── wallpaper_dynamic.sh
│   │
│   ├── vps/                   # Internet-facing VPS
│   │   ├── bootstrap.sh
│   │   ├── bootstrap/
│   │   │   ├── install.sh
│   │   │   ├── configure.sh
│   │   │   ├── links.sh
│   │   │   └── lib.sh
│   │   └── dockge/
│   │       ├── dockge/
│   │       │   └── compose.yaml
│   │       └── stacks/
│   │           ├── hermes/
│   │           │   ├── .gitconfig
│   │           │   └── compose.yaml
│   │           ├── tailscale/          # Tailscale sidecar
│   │           │   ├── README.md
│   │           │   ├── .env.example
│   │           │   ├── compose.yaml
│   │           │   └── config/
│   │           ├── traefik/
│   │           │   ├── compose.yaml
│   │           │   └── config/
│   │           │       ├── acme/.keep
│   │           │       ├── dynamic/.keep
│   │           │       └── traefik.yml
│   │           └── gitea/
│   │               ├── README.md
│   │               ├── .env.example
│   │               ├── compose.yaml
│   │               └── config/
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
    ├── docker_claude/
    │   └── claude
    ├── docker_copilot_cli/
    │   └── copilot
    ├── docker_hermes/
    │   └── hermes_local
    ├── docker_run_or_exec/
    │   └── docker-run_or_exec
    ├── install/
    │   └── link
    └── install_list.sh
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

### media

| Item | Value |
|------|-------|
| Location | Home LAN |
| OS | Ubuntu |
| Connectivity | Wired Ethernet + Tailscale |
|| Status | Dockge stacks ready (gitea, jellyfin, metube, plex, qbittorrent, syncthing, traefik, whoami) |

### pi

| Item | Value |
|------|-------|
| Location | Home LAN |
| OS | Raspberry Pi OS (Debian-based) |
| Connectivity | Wired Ethernet + Tailscale |
| Services | Pi-hole (DNS sinkhole, local DNS) |
| DNS role | Primary DNS for the tailnet |
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
| Stacks | Dockge, Traefik, Hermes Agent, Tailscale |
| Hermes | Docker container, git identity mounted from stack |
| Docker network | `proxy` (external, shared across stacks) |

---

## Notes

- **`install/`** contains reusable install scripts. Each host's bootstrap scripts under `bootstrap/install.sh` reference them by path.
- **All hosts** follow a `bootstrap.sh` → `bootstrap/{install,configure,links,lib}.sh` pattern. Run `bash hosts/<name>/bootstrap.sh` for the full setup.
- **`scripts/`** contains Docker wrappers (Claude, Copilot CLI, Hermes) and the `link` utility for symlinks.
- **`dotfiles/`** only covers config files currently in active use.
- **`projects/`**, **`bootstrap/`**, and backup/restore scripts do not exist yet.
- **Docs** are evolving: `networking.md` and `repository-structure.md` exist alongside this file.
