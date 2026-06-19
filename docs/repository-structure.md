# Homelab Repository Structure

This repository contains everything required to provision, configure, operate, and recover the homelab.

The design goals are:

- Git as the source of truth
- Docker Compose as the deployment format
- Dockge as an operational UI
- Traefik as the reverse proxy
- Host-centric organization
- Easy disaster recovery
- Reproducible workstation setups

---

## Repository Layout

```
homelab/
├── README.md
├── .gitignore
│
├── bootstrap/
│   ├── common.sh
│   ├── docker.sh
│   ├── media.sh
│   ├── apps.sh
│   ├── pi.sh
│   ├── vps.sh
│   ├── ubuntu-server.sh
│   └── ubuntu-desktop.sh
│
├── dotfiles/
│   ├── zsh/
│   ├── bash/
│   ├── git/
│   ├── tmux/
│   ├── ssh/
│   ├── vim/
│   ├── nvim/
│   └── vscode/
│
├── projects/
│   ├── bz/
│   ├── dropbox-sync/
│   ├── homelab-tools/
│   ├── agent-tools/
│   └── experiments/
│
├── scripts/
│   ├── backup.sh
│   ├── restore.sh
│   ├── update-all.sh
│   ├── rsync-migrate.sh
│   └── install-dotfiles.sh
│
├── docs/
│   ├── architecture.md
│   ├── networking.md
│   ├── storage.md
│   ├── backups.md
│   ├── recovery.md
│   └── repository-structure.md
│
└── hosts/
    ├── pi/
    ├── media/
    ├── apps/
    ├── vps/
    └── laptops/
```

---

## Host Layout

Each host is self-contained.

A host directory should contain:

- Documentation
- Bootstrap scripts
- Docker stacks
- Configuration files
- Environment variables

Example:

```
hosts/media/
├── README.md
├── host.env
├── bootstrap.sh
│
├── configs/
│   ├── traefik/
│   ├── jellyfin/
│   └── plex/
│
└── stacks/
    ├── traefik/
    ├── dockge/
    ├── jellyfin/
    ├── plex/
    ├── sonarr/
    ├── radarr/
    └── metube/
```

The goal is that rebuilding a host should only require looking inside its own directory.

---

## Host Responsibilities

### pi

Infrastructure services.

- Pi-hole
- DNS
- WireGuard
- Tailscale
- Networking

### media

Media-related services.

- Traefik
- Dockge
- Jellyfin
- Plex
- Sonarr
- Radarr
- Prowlarr
- MeTube

### apps

Development and internal applications.

- Traefik
- Dockge
- Gitea
- OpenGist
- Postgres
- Redis
- Verdaccio (future)

### vps

Internet-facing services.

- Traefik
- Dockge
- Bots
- APIs
- Webites
- Agents

---

## Docker Principles

Every service should be defined using Docker Compose.

Example:

```
hosts/media/stacks/jellyfin/
└── docker-compose.yml
```

Dockge is a convenience layer.

The source of truth remains:

```
Git
    ↓
Docker Compose
    ↓
Docker
```

---

## Traefik Principles

Each Docker host runs its own Traefik instance.

Example:

```
Media Server
    jellyfin.home
    plex.home

App Server
    gitea.home
    gist.home

VPS
    api.example.com
    bot.example.com
```

A shared Docker network should be used:

```
docker network create proxy
```

All Traefik-managed services should join this network.

---

## Storage Layout

All servers should follow the same structure.

```
/srv/
├── homelab/
├── docker/
├── media/
├── downloads/
├── backups/
└── cache/
```

Container paths should reference these logical directories rather than disk devices.

Avoid:

```
/mnt/sdb1
/media/usb
```

Prefer:

```
/srv/media
/srv/backups
```

This simplifies future disk migrations.

---

## Project Layout

Reusable tools belong under `projects/`.

Example:

```
projects/bz/
├── bin/
├── completions/
├── docs/
├── tests/
└── install.sh
```

Projects are treated as software rather than dotfiles.

Common structure:

- `bin/`
- `completions/`
- `docs/`
- `tests/`
- `install.sh`

---

## Dotfiles

Dotfiles contain workstation configuration only.

Examples:

- Shell configuration
- Git configuration
- SSH configuration
- Editor configuration
- Terminal configuration

They should not contain large utilities or application logic.

---

## Disaster Recovery Goal

A replacement server should be recoverable through the following process:

```
git clone <repo>

./bootstrap/<host>.sh

docker compose up -d
```

No manual configuration should be required.

---

## Design Philosophy

Prefer:

- Simplicity
- Git-managed configuration
- Docker Compose
- Explicit configuration
- Host-centric organization

Avoid unnecessary abstraction layers.
The homelab should remain understandable from a terminal session and a Git repository without depending on a specific management UI.
