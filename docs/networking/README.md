# Network Architecture

Three isolated Docker networks, each with a distinct purpose.

## Networks

| Network | Purpose | Visibility | Typical containers |
|---------|---------|:----------:|-------------------|
| `VPS_NET` | Inter-container communication on the VPS | 🔒 VPS only | Gitea, databases, caches, agents |
| `Proxy` | Public reverse proxy (port 80/443) | 🌐 Internet via Traefik | Traefik, Gitea web, Jekyll, Calibre |
| `WireGuard` | VPN tunnel for remote access | 🚇 WireGuard clients | WireGuard server, dashboards |

## Topology

```
┌─ VPS ──────────────────────────────────────────────────┐
│                                                          │
│  ┌────────┐    ┌──────────────┐    ┌─────────────────┐  │
│  │ Proxy  │◄───┤   Traefik    ├────┤  WireGuard       │  │
│  │ (pub)  │    │              │    │  (port 51820/UDP) │  │
│  └────────┘    └──────────────┘    └────────┬─────────┘  │
│                           ▲                 │            │
│                     ┌─────┴─────┐           │            │
│                     │  VPS_NET   │◄──────────┘            │
│                     └─────┬─────┘                        │
│                           │                               │
│              ┌────────────┼────────────┐                  │
│              ▼            ▼            ▼                  │
│         ┌────────┐ ┌────────┐ ┌────────┐                 │
│         │ Gitea  │ │ Hermes │ │ Jekyll │  ...            │
│         └────────┘ └────────┘ └────────┘                 │
│                                                          │
└──────────────────────────────────────────────────────────┘

┌─ Homelab ───────────────────────────────────────────┐
│                                                     │
│  ┌──────────┐                                       │
│  │  Pi-hole │◄── WireGuard client (site-to-site) ─┐ │
│  │ (gateway)│                                      │ │
│  └──────────┘                                      │ │
│        │         ┌───────────┐    ┌──────────┐     │ │
│        ├─────────│   Media   │    │  Phone   │─────┘ │
│        │         │   Server  │    │  (WG app)│       │
│        │         └───────────┘    └──────────┘       │
│        │                                              │
│        └──── Android Server                           │
│                                                      │
└──────────────────────────────────────────────────────┘
```

## What goes where

### VPS_NET
Every container on the VPS that needs to talk to other containers.
- Databases (Postgres, SQLite)
- Backend services (Gitea, Hermes agent)
- **WireGuard server** — needs VPS_NET to route to other containers
- Minimum network for any container to function

### Proxy
Only containers that need a public URL via `*.vps`.
- **Traefik** — always on Proxy (it is the proxy)
- **Gitea** — gitea.vps
- **Jekyll** — docs.vps
- **Calibre** — books.vps

**Rule:** If it doesn't need a public hostname, it doesn't go on Proxy.

### WireGuard
No containers go on WireGuard. The WG server is on VPS_NET and routes traffic
to other containers by their Docker IP. Remote peers connect to the WG server
and reach containers transparently.

## Host connectivity

| Host | VPN role | Connects via |
|------|----------|-------------|
| **VPS** | WireGuard server (container) | Port 51820/UDP — single entry point |
| **Pi-hole** | WireGuard client (host-level) | Site-to-site: connects to VPS, routes homelab LAN |
| **Phone (Android)** | WireGuard client (app) | Connects to VPS, reaches VPS containers + homelab LAN through Pi-hole |

## Routing

```
Phone (4G) → VPS:51820/UDP
  └─ VPS WireGuard ──┬─ Pi-hole ── homelab LAN (192.168.0.0/24)
                     │             └─ Media Server (192.168.0.x:8096)
                     │             └─ Android Server (192.168.0.x)
                     │
                     └─ VPS_NET ─── Hermes (:9119)
                                   Gitea (:3000)
                                   Jekyll (:8080)
```

All traffic routes through the VPS (hub-and-spoke). Single port open: 51820/UDP.
