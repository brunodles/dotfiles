# Remote Access

Accessing homelab + VPS services from outside (4G, work WiFi, etc.).

## Architecture

```
Phone (4G)
  │
  ├─ Tailscale VPN (always on) ──┬─ Pi-hole subnet ── Media Server (Jellyfin)
  │  (WireGuard tunnel)          │                  └─ Android Server
  │                              └─ VPS (TS sidecar) ─┴ Hermes dashboard
  │                                                     Gitea (TS)
  │
  └─ Regular browsing → still uses 4G directly
     (if split-DNS is configured)
```

## Phone (Android)

### 1. Install Tailscale

```
Play Store → Tailscale → Install
```

### 2. Sign in

Open app → **Sign in** → browser opens → authenticate with the same account used
for Pi-hole/VPS.

### 3. Enable VPN

Toggle **Connected** to ON. The phone now participates in the tailnet.

### 4. Browse

Open Chrome and go to:

```bash
# Pi-hole (DNS admin)
http://pi-hole.bruno-ts.ts.net/admin

# Media Server (Jellyfin) — via Pi-hole subnet
http://192.168.0.50:8096

# Hermes dashboard — via VPS Tailscale
http://vps.bruno-ts.ts.net:9119
```

Type the URL directly in the address bar. No app needed, no Termux, no proxy
configuration. Tailscale VPN handles routing transparently.

## Browser access on desktop (Linux/Windows/Mac)

Install Tailscale: https://tailscale.com/download

Same flow: install → sign in → browse. The desktop client shows which services
are available in its **MagicDNS** list.

## Split DNS (optional)

By default, Tailscale routes all traffic through the tunnel. If you want only
tailnet traffic to use the VPN and keep regular browsing on 4G directly:

1. Open Tailscale app → **Settings**
2. **Use Tailscale DNS** → ON
3. **Split DNS** → ON (routes only `*.ts.net` domains through the tunnel)

This means:
- `http://pi-hole.bruno-ts.ts.net` → goes through VPN → resolved by MagicDNS
- `https://google.com` → goes through 4G directly (no latency)

## Without Tailscale (fallback)

If Tailscale is down or not installed:

| Service | Alternative | Requires |
|---------|-------------|----------|
| Jellyfin | `jellyfin.vps` (public) | Traefik + Proxy net + auth |
| Hermes | Not available | Tailscale only |
| Gitea | `gitea.vps` (public) | Traefik + Proxy net |

The fallback is intentionally limited — most services are Tailscale-only for
security.

## Decision record

### Why VPN over Funnel/Cloudflare

| Option | App needed? | Security | Latency |
|--------|:-----------:|:--------:|:-------:|
| **Tailscale VPN** (chosen) | ✅ Tailscale app | 🔒 Zero-trust, no public ports | Direct peer-to-peer |
| Tailscale Funnel | ❌ Any browser | ⚠️ Public by default | Direct |
| Cloudflare Tunnel + Access | ❌ Any browser | 🟡 CF handles auth | VPS relay |

Tailscale VPN was chosen because:
- No public attack surface (no ports open)
- Direct peer-to-peer connections (no relay latency)
- Works everywhere (4G, work WiFi, hotel)
- Zero-trust model — device must be authorized in the tailnet
