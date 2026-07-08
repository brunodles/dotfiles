# Network Decisions (ADR)

Architecture Decision Records for the homelab + VPS networking setup.

---

## ADR-001: Three-network architecture

**Date:** 2026-07-06

**Context:** Containers on the VPS need different levels of visibility.
Some must be public (Gitea, Jekyll), some internal (databases, caches), and
some admin-only (Hermes dashboard, monitoring).

**Decision:** Use three isolated Docker networks:

| Network | Scope | External access |
|---------|-------|:---------------:|
| `VPS_NET` | Inter-container communication on VPS | ❌ None |
| `Proxy` | Services exposed via reverse proxy | 🌐 Port 80/443 (Traefik) |
| `WireGuard` | VPN tunnel for remote access | 🚇 Port 51820/UDP |

**Consequences:**
- ✅ Containers can be on multiple networks (e.g. Gitea on VPS_NET + Proxy)
- ✅ Traefik is the only container on Proxy that receives external connections
- ✅ Dashboards and admin UIs are reachable only via WireGuard
- ⚠️ +1 network to manage vs the previous single `proxy` approach
- ⚠️ Every stack needs explicit network assignment

**Alternatives considered:**

| Alternative | Why rejected |
|-------------|--------------|
| Single `proxy` net | Every container visible to reverse proxy; no isolation |
| Docker network per visibility | Too many networks, hard to manage |

---

## ADR-002: Pi-hole as VPN gateway

**Date:** 2026-07-06

**Context:** The homelab needs a peer to relay traffic from the VPS WireGuard
server to the homelab LAN, so remote devices can reach Media Server, Android
Server, etc.

**Candidates:**

| Host | Can be WireGuard peer? | Pros | Cons |
|------|:---------------------:|------|------|
| **Pi-hole** (chosen) | ✅ Linux | Already runs 24/7, central DNS, low power | Subnet routing + DNS + Pi-hole is modest CPU |
| Media Server | ✅ Linux | More CPU/RAM, already serves content | Runs Docker stacks, restarts can drop WG |
| Android Server | ❌ Android | Always on | Cannot be WG peer (no kernel WG) |

**Decision:** Pi-hole as WireGuard site-to-site peer + subnet router.

**Consequences:**
- ✅ Pi-hole is always on, rarely rebooted
- ✅ All homelab devices reachable via Pi-hole's subnet routing
- ⚠️ Pi-hole needs `ip_forward=1` and iptables masquerade
- ⚠️ Pi-hole restarts briefly drop the VPN tunnel

---

## ADR-003: WireGuard over Tailscale

**Date:** 2026-07-06

**Context:** Secure remote access to homelab + VPS services from outside.

**Options:**

| Approach | Open ports | Topology | Control |
|----------|:----------:|:--------:|:-------:|
| **WireGuard** (chosen) | 1 (51820/UDP) | Hub-and-spoke via VPS | Full |
| Tailscale | 0 | P2P → fallback DERP relay | Delegated to TS Inc |

**Decision:** WireGuard on the VPS.

**Rationale:**

Both options resolve to the same effective topology when both peers are behind
NAT/CGNAT (phone on 4G + homelab behind CGNAT):

- WireGuard: phone → VPS (relay) → Pi-hole → homelab
- Tailscale: phone → DERP relay → Pi-hole → homelab

Tailscale's P2P advantage is neutralised when both sides have restrictive NAT.
In practice the traffic goes through a relay either way — the difference is
**who owns the relay**. With WireGuard the relay is your own VPS; with
Tailscale it's Tailscale Inc (or a self-hosted DERP).

Chosen WireGuard because:
- ✅ Full control: you own the VPS, the keys, the config
- ✅ Single port: 51820/UDP — easy to firewall, monitor, audit
- ✅ No external dependency: even if Tailscale is down, your VPN works
- ✅ Simpler threat model: no third-party control plane
- ⚠️ Manual key management (trade-off for control)

---

## ADR-004: WireGuard as Docker container

**Date:** 2026-07-06

**Context:** The VPS needs a WireGuard server.

**Decision:** Run WireGuard as a Docker container (`linuxserver/wireguard`)
instead of on the host.

**Consequences:**
- ✅ Clean container-native networking — no host-level packages
- ✅ Auto-generates server keys + peer configs on first run
- ✅ Easy to update (just `docker compose pull && up -d`)
- ✅ Container is on `vps_net` — automatically routes to other containers
- ⚠️ Needs `NET_ADMIN` + `SYS_MODULE` capabilities + `/dev/net/tun`
- ⚠️ Kernel module loads inside container (needs `SYS_MODULE`)

---

## ADR-005: Phone split-tunnel

**Date:** 2026-07-06

**Context:** Phone needs to access VPS/homelab services without routing all
internet traffic through the VPS (which would waste bandwidth and add latency).

**Decision:** AllowedIPs restricted to Docker + homelab subnets only.

```ini
AllowedIPs = 10.0.0.0/24, 172.16.0.0/12, 192.168.0.0/24
```

**Consequences:**
- ✅ Daily browsing uses 4G directly (no VPS bandwidth consumed)
- ✅ No additional latency for YouTube, WhatsApp, etc.
- ✅ VPS bandwidth reserved for actual homelab/VPS traffic
- ⚠️ Adding a new Docker network requires updating AllowedIPs on the phone
