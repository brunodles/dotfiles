# Remote Access

Accessing homelab + VPS services from outside (4G, work WiFi, etc.).

## Architecture

```
Phone (4G)
  │
  └─ WireGuard tunnel (always-on) ── VPS:51820/UDP
       │
       ├─ VPS_NET ─── Hermes (:9119), Gitea (:3000), …
       │
       └─ Pi-hole (site-to-site) ── homelab LAN
            Media Server (:8096), Android Server, Pi-hole admin
```

## Phone (Android)

### 1. Install WireGuard

```
Play Store → WireGuard → Install
```

### 2. Add tunnel

On the VPS:

```bash
docker exec wireguard /app/show-peer phone
```

The command prints a QR code. In the WireGuard app:
- Tap **+** → **Scan from QR code**
- Point at the terminal

### 3. Customize AllowedIPs

After scanning, tap the tunnel name → **Edit**. Check **AllowedIPs**:

```diff
- 10.0.0.2/32
+ 10.0.0.2/32, 172.16.0.0/12, 192.168.0.0/24
```

This tells the phone which traffic goes through the tunnel. Everything else
uses 4G directly.

### 4. Connect

Toggle ON. The VPN icon appears in the status bar.

### 5. Browse

Open Chrome and go to:

```bash
# VPS containers (Docker DNS — via VPS_NET)
http://hermes:9119
http://gitea:3000

# Homelab services (via Pi-hole subnet routing)
http://192.168.0.50:8096     # Media Server / Jellyfin
http://192.168.0.5           # Pi-hole
http://192.168.0.10          # Android Server
```

Works on 4G, work WiFi, hotel WiFi — any internet.

## Desktop (laptop)

Same flow:

1. Install WireGuard from https://www.wireguard.com/install/
2. Scan QR or import conf file
3. Connect

## Adding a new device

```bash
# On the VPS:
docker stop wireguard

# Edit /config/wg0.conf — add a new [Peer] block:
# [Peer]
# # laptop
# PublicKey = <new-key>
# PresharedKey = <new-psk>
# AllowedIPs = 10.0.0.4/32

docker start wireguard
```

Or use the linuxserver/wireguard `PEERS` env var to auto-generate.

## Battery and performance

- WireGuard uses the kernel module on Android (no battery drain)
- Throughput is limited by the VPS bandwidth (upload speed)
- Hub-and-spoke: every packet routes through the VPS
- Expect 20-50ms added latency (phone → VPS → homelab vs direct)

## Security

- **Single open port:** 51820/UDP on the VPS
- **No public DNS:** services are not exposed to the internet
- **Per-device keys:** revoke a device by removing its [Peer] block
- **No middleman:** the VPS is your relay, you own it
- **Split tunnel:** phone traffic to the internet is NOT routed through the VPN
  (only Docker + homelab ranges)
