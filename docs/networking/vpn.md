# VPN Setup (WireGuard)

Architecture: **Hub-and-spoke** via VPS. Single port open.

```
Phone (4G) ──┬── VPS:51820/UDP ──┬── Pi-hole ── homelab LAN
              │                   │
              │                   └── VPS_NET ── Gitea, Hermes, Jekyll, …
              │
              └── other WireGuard peers (laptop, etc.)
```

---

## 1. VPS — WireGuard server (Docker)

### Deploy

```bash
cd /opt/stacks/wireguard

# Set your public IP
echo "SERVERURL=vps.seu-dominio.com" >> .env

docker compose up -d
```

Wait for first run — the container generates server keys + peer configs:

```bash
# View phone config (QR code for app)
docker exec wireguard /app/show-peer phone

# View Pi-hole config (copy to Pi-hole)
docker exec wireguard /app/show-peer pihole
```

### Customize AllowedIPs

The auto-generated config restricts each peer to its own WG IP. Edit
`/config/wg0.conf` and add Docker + homelab ranges to the **phone** peer:

```ini
[Peer]
# phone
PublicKey = <key>
PresharedKey = <psk>
AllowedIPs = 10.0.0.2/32, 172.16.0.0/12, 192.168.0.0/24
```

Then restart:

```bash
docker exec wireguard wg-quick down wg0
docker exec wireguard wg-quick up wg0
```

### Find Docker network subnets

On the VPS host, check your custom network subnets:

```bash
docker network inspect vps_net   | grep Subnet
docker network inspect proxy     | grep Subnet
```

Add those ranges to the phone's `AllowedIPs` so the phone can route to
containers.

---

## 2. Pi-hole — WireGuard client (site-to-site)

Pi-hole connects as a peer so the phone can reach the homelab LAN through it.

### Install

```bash
# SSH into Pi-hole
ssh pi@pihole.lab

# Install WireGuard
sudo apt install wireguard

# Create config
sudo nano /etc/wireguard/wg0.conf
```

### Config (`/etc/wireguard/wg0.conf`)

```ini
[Interface]
Address = 10.0.0.3/32
PrivateKey = <pihole-private-key-from-peer-config>

# Enable routing
PostUp = sysctl -w net.ipv4.ip_forward=1
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = <vps-public-key>
PresharedKey = <psk>
Endpoint = vps.seu-dominio.com:51820
AllowedIPs = 10.0.0.0/24
PersistentKeepalive = 25
```

### Start

```bash
sudo wg-quick up wg0
sudo systemctl enable wg-quick@wg0
```

### Permanent IP forwarding

```bash
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-wireguard.conf
```

### Verify

```bash
sudo wg show
# → interface: wg0, public key: …, listening port: 12345
#   peer: <vps-key> endpoint: vps:51820 allowed ips: 10.0.0.0/24
```

---

## 3. Phone — WireGuard client (Android)

### Install

1. Play Store → **WireGuard** → Install
2. Open app → **+** → **Scan from QR code**
3. Point at the QR from `docker exec wireguard /app/show-peer phone`

### After import

Edit the tunnel settings and check **AllowedIPs**. It should include:

```
10.0.0.0/24, 172.16.0.0/12, 192.168.0.0/24
```

If the auto-generated config only has `10.0.0.2/32`, update the server-side
config (step 1) and regenerate.

### Connect

Toggle the tunnel ON. The phone now routes Docker + homelab traffic through
the VPS. Regular browsing still uses 4G.

### Access targets

| Service | URL (via WireGuard) | Notes |
|---------|---------------------|-------|
| Hermes dashboard | `http://hermes:9119` | Via Docker DNS on VPS_NET |
| Gitea | `http://gitea:3000` | Via Docker DNS on VPS_NET |
| Jellyfin | `http://192.168.0.x:8096` | Via Pi-hole subnet routing |
| Android Server | `http://192.168.0.x:xxxx` | Via Pi-hole subnet routing |
| Pi-hole admin | `http://192.168.0.x/admin` | Via Pi-hole subnet routing |

> **Note:** Containers are reachable by Docker service name because the WG
> container is on `vps_net`. The phone's traffic enters the WG container,
> which is on `vps_net`, so Docker DNS resolves names like `hermes` to the
> container IP.

---

## Alternative: Tailscale

Tailscale is documented in `stacks/hermes/README.md` as an alternative
approach. It uses the same topology (phone → relay → homelab) but with
automatic key management and MagicDNS instead of manual config.

Not recommended as primary because:
- Same effective topology (hub-and-spoke through a relay)
- DERP relay dependency when both peers are behind CGNAT
- Control plane depends on Tailscale servers
