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
| Services | Pi-hole (DNS sinkhole, local DNS), Tailscale subnet router |
| DNS role | Primary DNS for the tailnet |
| Access | LAN + Tailscale |
| Subnet router | `192.168.${SUBNET}.0/24` advertised to tailnet |

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

## Subnet Routing

The VPS reaches the home LAN `192.168.x.0/24` through the **Pi** acting as a Tailscale subnet router. Any device on the home LAN is reachable from the tailnet — even devices without Tailscale installed (printers, IoT, TVs).

| Endpoint | Advertises | Accepts | Enables |
|----------|------------|---------|---------|
| **Pi** (subnet router) | `--advertise-routes=192.168.${SUBNET}.0/24` | — | VPS → any LAN device |
| **VPS** (sidecar) | — | `--accept-routes` | LAN devices → VPS (via return route) |

### Configuration

**Pi** (native Tailscale):
```bash
tailscale up --advertise-routes=192.168.${SUBNET}.0/24 --authkey=${TS_AUTHKEY}
```

**VPS** (Docker sidecar):
```yaml
environment:
  - TS_EXTRA_ARGS=--accept-dns=true --accept-routes
```

> By default Tailscale applies SNAT (masquerading) to traffic through the subnet router, so LAN devices see the Pi's IP as the source. Add `--snat-subnet-routes=false` on the Pi to preserve original source IPs (Linux only).

### Connectivity

| From | To | Path |
|------|----|------|
| VPS | `192.168.x.10` (printer) | VPS → Tailnet → Pi → LAN |
| VPS | `192.168.x.20` (smart TV) | VPS → Tailnet → Pi → LAN |
| VPS | Any LAN device | Via Pi as gateway |

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
                          │       Pi-hole        │
                          │  (dnsmasq)            │
                          │  192.168.x.xx  (LAN) │
                          │  100.x.x.xx  (TN)    │
                          ├──────────────────────┤
                          │ Blocklists           │
                          │ Local DNS records ←──┼── apply-dns.sh
                          │ Custom CNAME entries │     (from central
                          └──────┬───────────────┘      dns-config.yaml)
                                 │
                     ┌───────────┴───────────┐
                     │   Android (Dnsmasq)    │
                     │   192.168.x.xx  (LAN)  │
                     │   port 53              │
                     ├───────────────────────┤
                     │ Primary: Pi-hole       │
                     │ Fallback: Cloudflare   │
                     │ Local DNS records ←────┼── apply-dns.sh
                     └───────────────────────┘     (same source)
```

The homelab has two DNS servers sharing the same config source:

| Host | Software | Role | Config source |
|------|----------|------|--------------|
| **Pi** | Pi-hole (dnsmasq) | Primary DNS, ad-blocking, local records | Pi-hole admin + `scripts/dns/dns-config.yaml` via `apply-dns.sh` |
| **Android** | Dnsmasq | Secondary DNS, fallback to Cloudflare, local records | `scripts/dns/dns-config.yaml` via `apply-dns.sh` |

**Config centralization:**

Local DNS records (static hosts, CNAMEs) are defined once in
`scripts/dns/dns-config.yaml` (or `dns-config.example.yaml` as
template) and deployed to both hosts via
`scripts/dns/apply-dns.sh`:

- **Pi**: creates `/etc/dnsmasq.d/99-homelab.conf` (local records only)
- **Android**: creates `/data/data/com.termux/files/usr/etc/dnsmasq.conf` (full config)

Pi-hole continues to manage its own upstreams and blocklists
independently via its admin UI or CLI.

---

## Port Summary

| Host | Service | Port | Access |
|------|---------|------|--------|
| VPS | HTTP / HTTPS (Traefik) | `80`, `443` | Public |
| VPS | SSH | `22` | Restrict to known IPs or use Tailscale |
| VPS | Hermes Gateway | `8642` | Known IPs only |
| VPS | Hermes Dashboard | `9119` | Known IPs only |
| VPS | Gitea | `3000` | Tailscale only |
| VPS | Dockge | `5001` | Tailscale only |
| VPS | Tailscale | `UDP 41641` | Tailscale wireguard |
| Android | SSH | `8022` | LAN + Tailscale |
| Android | DNS (Dnsmasq) | `53` UDP | LAN + Tailscale |
| Pi | Pi-hole DNS | `53` UDP | LAN + Tailscale |
| Pi | Pi-hole Admin | `80` or `8080` | LAN + Tailscale |
| Media | Jellyfin / Plex / *arr | Various | LAN only |
| Apps | Gitea / Postgres / Redis | Various | LAN only |

---

## Firewall Rules

### VPS (public-facing)

```
Allow:  80/tcp, 443/tcp          (Traefik — public web traffic)
Allow:  22/tcp                    (SSH — restrict to your IP or use Tailscale SSH)
Allow:  8642/tcp, 9119/tcp       (Hermes — restrict to known IPs)
Deny:   all other inbound        (Gitea 3000, Dockge 5001 blocked from internet)
Allow:  all outbound
```

Gitea (3000) and Dockge (5001) are **not exposed to the internet**.
They are reachable only via:
- **Tailscale** — from any device on the tailnet
- **Docker internal** — between containers on the `proxy` network

### Home LAN hosts

```
Allow:  SSH from LAN + Tailscale subnets
Allow:  Service ports from LAN + Tailscale subnets
Deny:   All inbound from WAN
```

---

## Future Considerations

- **Split DNS**: Internal services resolve via Pi-hole (`.home` / `.internal` domains); external DNS resolves public domains for the VPS.
- **Exit node**: Optionally use the VPS as a Tailscale exit node to route home traffic through its public IP.
