# Network Architecture

Three isolated Docker networks, each with a distinct purpose.

## Networks

| Network | Purpose | Visibility | Typical containers |
|---------|---------|:----------:|-------------------|
| `VPS_NET` | Inter-container communication on the VPS | 🔒 VPS only | Gitea, databases, caches, agents |
| `Proxy` | Public reverse proxy (port 80/443) | 🌐 Internet via Traefik | Traefik, Gitea web, Jekyll, Calibre |
| `Tailscale` | Private tunnel via Tailscale | 🚇 Tailscale tailnet | Dashboards, admin UIs, monitoring |

## Topology

```
┌─ VPS ─────────────────────────────────────────────────┐
│                                                        │
│  ┌──────┐    ┌────────────┐    ┌──────────────────┐   │
│  │Proxy │◄───┤   Traefik  ├────┤   Tailscale      │   │
│  │(pub) │    └────────────┘    │   (TS container)  │   │
│  └──────┘          ▲           └────────┬─────────┘   │
│                    │                    │             │
│              ┌─────┴─────┐              │             │
│              │  VPS_NET   │◄─────────────┘             │
│              └─────┬─────┘                            │
│                    │                                   │
│         ┌──────────┼──────────┐                       │
│         ▼          ▼          ▼                       │
│    ┌────────┐ ┌────────┐ ┌────────┐                  │
│    │ Gitea  │ │ Hermes │ │ Jekyll │  ...              │
│    └────────┘ └────────┘ └────────┘                  │
│                                                        │
└────────────────────────────────────────────────────────┘

┌─ Homelab ───────────────────────────────────────────┐
│                                                      │
│  ┌──────────┐                                       │
│  │  Pi-hole │◄── Tailscale Subnet Router ───┐       │
│  │ (gateway)│                                │       │
│  └──────────┘                                │       │
│        │                                     │       │
│   ┌────┴────┐    ┌───────────┐    ┌────────┐ │       │
│   │  Media  │    │ Android   │    │ Phone  │─┘       │
│   │  Server │    │ Server    │    │ (TS    │         │
│   └─────────┘    └───────────┘    │  VPN)  │         │
│                                    └────────┘        │
└──────────────────────────────────────────────────────┘
```

## What goes where

### VPS_NET
Every container on the VPS that needs to talk to other containers.
- Databases (Postgres, SQLite shared volumes)
- Backend services (Gitea, Hermes agent)
- The **minimum** network for any container to function

### Proxy
Only containers that need a public URL via `traefik.lab` or `*.vps`.
- **Traefik** — always on Proxy (it is the proxy)
- **Gitea** — ssh.gitea.vps, gitea.vps
- **Jekyll** — docs.vps
- **Calibre** — books.vps

**Rule:** If it doesn't need a public hostname, it doesn't go on Proxy.

### Tailscale
Containers that should be accessible remotely but NOT publicly.
- Hermes dashboard (`hermes.lab:9119`)
- Admin UIs, monitoring, internal tools
- Anything you want to reach from your phone on 4G

## Host connectivity

| Host | Connects via | Role |
|------|-------------|------|
| **VPS** | Tailscale sidecar | Brings services on `Tailscale` net to remote devices |
| **Pi-hole** | Tailscale (installed on host) | Subnet router: routes homelab LAN to tailnet |
| **Phone (Android)** | Tailscale app (VPN) | Client: reaches VPS + homelab via tunnel |

## Routing

```
Phone (4G)
  └─ Tailscale VPN ──┬─ Pi-hole (subnet) ── Media server (192.168.x.x:8096)
                     │                     └─ Android server
                     └─ VPS Tailscale ───── Hermes dashboard (9119)
                                           └─ Gitea (optional, via TS)
```
