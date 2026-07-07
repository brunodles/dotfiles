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
| `Tailscale` | Services exposed via private tunnel | 🚇 Tailscale only |

**Consequences:**
- ✅ Containers can be on multiple networks (e.g. Gitea on VPS_NET + Proxy)
- ✅ Traefik is the only container on Proxy that receives external connections
- ✅ Dashboards and admin UIs stay off the public internet
- ⚠️ +1 network to manage vs the previous single `proxy` approach
- ⚠️ Every stack needs explicit network assignment

**Alternatives considered:**

| Alternative | Why rejected |
|-------------|--------------|
| Single `proxy` net | Every container visible to reverse proxy; no isolation |
| Docker network per visibility | Too many networks, hard to manage |
| No segmentation | Same as single proxy net |

---

## ADR-002: Pi-hole as Tailscale gateway

**Date:** 2026-07-06

**Context:** The homelab needs a Tailscale node to act as subnet router so
remote devices can reach Media Server, Android Server, and other LAN services.

**Candidates:**

| Host | Can be subnet router? | Pros | Cons |
|------|:--------------------:|------|------|
| **Pi-hole** (chosen) | ✅ Yes (Linux) | Already runs 24/7, central DNS, low power | Subnet routing + DNS + Pi-hole is modest CPU |
| Media Server | ✅ Yes (Linux) | More CPU/RAM, already serves content | Runs Docker stacks, restarts can drop TS |
| Android Server | ❌ No (Android) | Always on, battery-backed | Cannot advertise routes or act as exit node |

**Decision:** Pi-hole as Tailscale subnet router + MagicDNS resolver.

**Consequences:**
- ✅ Pi-hole's DNS + Tailscale MagicDNS = seamless name resolution
- ✅ Remote devices reach homelab LAN without installing TS on every device
- ✅ Pi-hole is always on, rarely rebooted
- ⚠️ Tailscale overhead on Pi-hole (~50-100MB RAM, negligible CPU)
- ⚠️ Pi-hole must approve subnet routes in admin console manually

---

## ADR-003: VPN over Funnel/proxy

**Date:** 2026-07-06

**Context:** Mobile access to homelab/VPS services from outside (4G, subway).

**Options:**

| Approach | App on phone? | Public attack surface | Latency |
|----------|:-------------:|:--------------------:|:-------:|
| **Tailscale VPN** (chosen) | ✅ Tailscale | ❌ None (zero ports) | Direct P2P |
| Tailscale Funnel | ❌ Any browser | ⚠️ Public hostname | Direct P2P |
| Cloudflare Tunnel + Access | ❌ Any browser | ✅ Auth'd via CF | Relayed via CF |

**Decision:** Tailscale VPN on the phone.

**Consequences:**
- ✅ Zero public ports on any service
- ✅ Direct peer-to-peer (lowest possible latency)
- ✅ Works on 4G, WiFi, hotel networks
- ⚠️ Requires Tailscale app installed on phone
- ⚠️ VPN must be toggled on (or always-on configured)

---

## ADR-004: VPS Tailscale as sidecar

**Date:** 2026-07-06

**Context:** VPS containers on the `Tailscale` network need to be reachable
from remote devices.

**Decision:** Run Tailscale as a Docker sidecar container (not on the host).

```yaml
services:
  tailscale:
    image: tailscale/tailscale:latest
    container_name: ts-vps
    hostname: vps
    networks:
      - vps_net
      - tailscale
```

**Consequences:**
- ✅ Clean container-native networking — no host-level install
- ✅ Easy to update (just `docker compose pull`), backup, restart
- ✅ Auth key via env var, no manual login on deploy
- ⚠️ Needs `NET_ADMIN` + `/dev/net/tun` capability
- ⚠️ Auth key rotation requires compose restart

---

## ADR-005: Phone always-on VPN

**Date:** 2026-07-06

**Context:** Phone needs to access homelab services spontaneously without
manual steps (open browser → it just works).

**Decision:** Tailscale app with split DNS enabled.

- **Always-on:** VPN connects automatically when not on home WiFi
- **Split DNS:** Only `*.ts.net` and LAN IPs route through the tunnel;
  regular browsing uses 4G directly

**Consequences:**
- ✅ Browser just works — no app toggle needed for casual use
- ✅ No battery penalty (WireGuard is efficient)
- ✅ No latency on regular browsing
- ⚠️ First-time setup needs to enable split DNS manually
