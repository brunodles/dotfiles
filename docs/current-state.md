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
│   └── repository-structure.md
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
├── host/                      # Host-specific configurations
│   ├── android/               # Android/Termux device
│   │   ├── README.md
│   │   ├── bootstrap.sh
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
│   │   └── bootstrap.sh
│   │
│   ├── silver/                # Desktop (Ubuntu, silver PC)
│   │   ├── README.md
│   │   ├── bootstrap.sh
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
│   │   └── home/.local/fbin/
│   │       └── _gr
│   │
│   └── vps/                   # Internet-facing VPS
│       ├── bootstrap.sh
│       └── dockge/
│           ├── dockge/
│           │   └── compose.yaml
│           └── stacks/
│               ├── hermes/
│               │   ├── .gitconfig
│               │   └── compose.yaml
│               └── traefik/
│                   ├── compose.yaml
│                   └── config/
│                       ├── acme/.keep
│                       ├── dynamic/.keep
│                       └── traefik.yml
│
├── install/                   # Install scripts (used by bootstrap.sh)
│   ├── _claudeCode.sh
│   ├── _fonts.sh
│   ├── _hermesAgent.sh
│   ├── _oh-my-zsh.sh
│   ├── _ollama.sh
│   ├── _samba.post-install.sh
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
| OS | Android + Termux |
| Package manager | `pkg` |
| Service manager | `termux-services` (runit/sv) |
| Shell | Zsh + Oh My Zsh + Powerlevel10k |
| SSH port | 8022 |

### media

| Item | Value |
|------|-------|
| OS | Ubuntu |
| Status | Only bootstrap.sh exists — no stacks yet |

### silver

| Item | Value |
|------|-------|
| OS | Ubuntu |
| Desktop | HyperLand (primary), i3wm (legacy) |
| Shell | Zsh + Oh My Zsh |
| Custom scripts | Network, wallpaper, terminal, Ollama, font management |

### vps

| Item | Value |
|------|-------|
| OS | Ubuntu (server) |
| Proxy | Traefik v3 (Docker provider + file provider) |
| SSL | Let's Encrypt (ACME) |
| Stacks | Dockge, Traefik, Hermes Agent |
| Hermes | Docker container, git identity mounted from stack |
| Docker network | `proxy` (external) |

---

## Observações

- **`install/`** contém os scripts de instalação. Cada host referencia esses scripts no seu `bootstrap.sh`.
- **Nenhum host** segue ainda o padrão completo com `host.env`, `configs/` e `stacks/` — a estrutura atual é mais simples.
- **`scripts/`** contém wrappers Docker (Claude, Copilot CLI, Hermes) e o utilitário `link` para criar symlinks.
- **`dotfiles/`** cobre apenas os config files que estão ativamente em uso.
- **Não há** `projects/`, `bootstrap/`, nem scripts de backup/restore ainda.
