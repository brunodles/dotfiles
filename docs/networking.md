# Networking

Network topology for the homelab.

---

## Layers

```
                         Internet
                            │
                     ┌──────┴──────┐
                     │    VPS      │  Public IP
                     │  (digital   │
                     │   ocean)    │
                     └──────┬──────┘
                            │
                      Tailscale │
                     (100.x.x.x)│
                            │
              ┌─────────────┼─────────────┐
              │             │             │
         ┌────┴────┐  ┌────┴────┐  ┌────┴────┐
         │  Home   │  │  Home   │  │  Home   │
         │  LAN    │  │  LAN    │  │  LAN    │
         │ (wired) │  │ (wired) │  │ (wifi)  │
         └─────────┘  └─────────┘  └─────────┘
              │             │             │
         ┌────┴────┐  ┌────┴────┐  ┌────┴────┐
         │ Media   │  │   Pi    │  │ Android │
         │ Server  │  │(Pi-hole)│  │ Server  │
         └─────────┘  └─────────┘  └─────────┘
              │
         ┌────┴────┐  ┌────┴────┐
         │ Silver  │  │  Apps   │
         │(desktop)│  │ Server  │
         └─────────┘  └─────────┘
```

## Host Connectivity

### VPS

| Field | Value |
|-------|-------|
| Location | Cloud (Digital Ocean / similar) |
| Public IP | `x.x.x.x` |
| Tailnet IP | `100.x.x.x` |
| Access | Public internet (80, 443, SSH) + Tailscale |
| DNS | External (Cloudflare / registrar) |
| Purpose | Public-facing services: Traefik, Hermes, bots, APIs |

### Home LAN

| Field | Value |
|-------|-------|
| Network | `192.168.x.0/24` |
| Gateway | Home router |
| DHCP | Router (static reservations for servers) |
| DNS | Pi-hole |
| Internet | ISP, NAT behind router |

### Media

| Field | Value |
|-------|-------|
| Connection | Wired Ethernet |
| IP | Static reservation |
| Tailnet IP | `100.x.x.x` |
| Services | Jellyfin, Plex, Sonarr, Radarr, *arr |
| Traefik | Local reverse proxy (home subdomains) |
| Access | LAN + Tailscale |

### Pi

| Field | Value |
|-------|-------|
| Connection | Wired Ethernet |
| IP | Static reservation |
| Tailnet IP | `100.x.x.x` |
| Services | Pi-hole (DNS sinkhole, local DNS) |
| DNS role | Primary DNS for the tailnet |
| Access | LAN + Tailscale |

### Android Server

| Field | Value |
|-------|-------|
| Connection | Wi-Fi (or USB/OTG Ethernet) |
| IP | DHCP reservation (MAC-based) |
| Tailnet IP | `100.x.x.x` |
| Services | SSH (port 8022), Tailscale, reverse tunnel fallback |
| Access | LAN (SSH) + Tailscale |
| Power | Always plugged in, battery saver off, wakelock on |

### Silver

| Field | Value |
|-------|-------|
| OS | Ubuntu Desktop (HyperLand / i3wm) |
| Connection | Wired Ethernet |
| IP | DHCP reservation |
| Tailnet IP | `100.x.x.x` |
| Purpose | Development workstation, Ollama |
| Access | LAN + Tailscale |

### Apps

| Field | Value |
|-------|-------|
| Connection | Wired Ethernet |
| IP | Static reservation |
| Tailnet IP | `100.x.x.x` |
| Services | Gitea, OpenGist, Postgres, Redis, Verdaccio (future) |
| Traefik | Local reverse proxy (dev subdomains) |
| Access | LAN + Tailscale (internal only, no public exposure) |

---

## Connectivity Matrix

| ↓ From \ To → | VPS | Pi | Media | Android | Silver | Apps |
|---------------|-----|----|-------|---------|--------|------|
| **VPS** | — | Tailnet | Tailnet | Tailnet | Tailnet | Tailnet |
| **Pi** | Tailnet | — | LAN | LAN | LAN | LAN |
| **Media** | Tailnet | LAN | — | LAN | LAN | LAN |
| **Android** | Tailnet | LAN | LAN | — | LAN | LAN |
| **Silver** | Tailnet | LAN | LAN | LAN | — | LAN |
| **Apps** | Tailnet | LAN | LAN | LAN | LAN | — |

**LAN** = `192.168.x.x` direct (low latency, high bandwidth)\
**Tailnet** = `100.x.x.x` via Tailscale (encrypted, NAT traversal)

---

## DNS Architecture

```
  ┌──────────────────────────────────────────────┐
  │           Tailscale Admin Console            │
  │  → Global nameserver: Pi-hole Tailnet IP     │
  │  → MagicDNS: enabled                         │
  └──────────────────────┬───────────────────────┘
                         │
          All tailnet devices use Pi-hole
                         │
              ┌──────────┴──────────┐
              │       Pi-hole       │
              │  192.168.x.xx  (LAN)│
              │  100.x.x.xx  (TN)   │
              ├─────────────────────┤
              │ Blocklists (ad/track)│
              │ Local DNS records   │
              │ Custom CNAME entries│
              └─────────────────────┘
```

Pi-hole is the central DNS for the entire homelab:

1. **Local hosts** point to Pi-hole via DHCP or manual config
2. **Tailscale global nameserver** = Pi-hole tailnet IP
3. **All devices** (local + remote via Tailscale) get ad-blocking DNS
4. **Local DNS records** resolve home services by hostname

---

## Port Summary

| Host | Service | Port |
|------|---------|------|
| VPS | HTTP / HTTPS (Traefik) | `80`, `443` |
| VPS | SSH | `22` (or restrict to Tailscale) |
| VPS | Hermes Gateway | `8642` |
| VPS | Hermes Dashboard | `9119` |
| Android | SSH | `8022` |
| Pi | Pi-hole DNS | `53` UDP |
| Pi | Pi-hole Admin | `80` or `8080` |
| Media | Jellyfin / Plex / *arr | Various (LAN only) |
| Apps | Gitea / Postgres / Redis | Various (LAN only) |

---

## Firewall Rules

### VPS (public-facing)

```
Allow:  80/tcp, 443/tcp          (Traefik — public web traffic)
Allow:  22/tcp                    (SSH — restrict to your IP or use Tailscale SSH)
Allow:  8642/tcp, 9119/tcp       (Hermes — restrict to known IPs)
Deny:   all other inbound
Allow:  all outbound
```

### Home LAN hosts

```
Allow:  SSH from LAN + Tailscale subnets
Allow:  Service ports from LAN + Tailscale subnets
Deny:   All inbound from WAN
```

---

## Future Considerations

- **Subnet routing**: If a device on the home LAN cannot run Tailscale (IoT, TV, printer), one of the home hosts can advertise a subnet route via Tailscale so the VPS can reach it.
- **Split DNS**: Internal services resolve via Pi-hole (`.home` / `.internal` domains); external DNS resolves public domains for the VPS.
- **Exit node**: Optionally use the VPS as a Tailscale exit node to route home traffic through its public IP.
