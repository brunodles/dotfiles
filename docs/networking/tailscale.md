# Tailscale Setup

Gateway: **Pi-hole** (subnet router + DNS)  
Phone: **Tailscale app (VPN)**

---

## 0. Create a tailnet

If you don't have one yet:

1. Go to https://login.tailscale.com
2. Sign in with Google/GitHub/Microsoft
3. Choose a tailnet name (e.g. `bruno-ts`)

> **Tailnet** is your private network. Every device that joins sees the others
> by their MagicDNS names (`pi-hole.bruno-ts.ts.net`, `vps.bruno-ts.ts.net`).

---

## 1. Pi-hole (homelab gateway)

Pi-hole is the **subnet router** — it routes the homelab LAN (192.168.x.x) into
the tailnet so remote devices can reach Media Server, Android Server, etc.

### Install Tailscale

```bash
# SSH into Pi-hole
ssh pi@pi-hole.lab

# Install
curl -fsSL https://tailscale.com/install.sh | sh

# Authenticate (prints a URL to visit)
sudo tailscale up --advertise-routes=192.168.0.0/24 --accept-dns --accept-routes
```

| Flag | Why |
|------|-----|
| `--advertise-routes=192.168.0.0/24` | Tells Tailscale "route my LAN through me". Replace with your actual subnet. |
| `--accept-dns` | Enables MagicDNS — access devices by name instead of IP. |
| `--accept-routes` | Accept subnet routes from other nodes (like VPS). |

### Configure subnet routing in admin console

After `tailscale up`, go to:  
**https://login.tailscale.com/admin/machines** → click Pi-hole → **Edit route settings** → **Approve** the advertised routes.

Without this manual approval, Tailscale won't actually route the subnet.

### Verify

```bash
tailscale status
# → pi-hole    bruno-ts     linux    active; direct x.x.x.x:41641
```

From a remote device (phone on 4G):
```bash
# Ping the Media Server by LAN IP
ping 192.168.0.50   # or whatever the media server's IP is
# → should reply
```

---

## 2. VPS (Tailscale sidecar)

The VPS needs Tailscale so services on the `Tailscale` network are reachable
from your phone.

### Option A: Docker sidecar (recommended)

Add a `tailscale` service to `stacks/vps-net/tailscale/compose.yaml`:

```yaml
services:
  tailscale:
    image: tailscale/tailscale:latest
    container_name: ts-vps
    hostname: vps
    restart: unless-stopped
    environment:
      - TS_AUTHKEY=tskey-auth-xxxxx   # from admin console
      - TS_STATE_DIR=/var/lib/tailscale
      - TS_USERSPACE=false
      - TS_EXTRA_ARGS=--accept-dns --accept-routes
    volumes:
      - ts-state:/var/lib/tailscale
      - /dev/net/tun:/dev/net/tun
    cap_add:
      - NET_ADMIN
      - NET_SYS_MODULE
    networks:
      - vps_net     # shares network with other VPS containers
      - tailscale   # services on this net become TS-reachable

volumes:
  ts-state:

networks:
  vps_net:
    external: true
  tailscale:
    external: true
```

### Option B: Host-level install

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --accept-dns --accept-routes
```

Then any container port published to the host can be reached via the VPS's
Tailscale IP.

### Auth keys

To avoid manual login on every deploy:

1. Go to **https://login.tailscale.com/admin/settings/keys**
2. Generate an **auth key** (reusable, tagged `container`)
3. Set `TS_AUTHKEY=tskey-auth-xxxxx` in the container env

---

## 3. Phone (Android VPN)

This is what gives you browser access from the subway/metro.

### Install

1. Open Play Store → search **Tailscale** → Install
2. Open app → Sign in with the same account
3. Toggle **VPN on**

### How it works

- The phone creates a WireGuard tunnel to the tailnet
- All traffic (or only tailnet traffic, configurable) routes through it
- Open Chrome → access `pi-hole.bruno-ts.ts.net` or `vps.bruno-ts.ts.net`
- Or use LAN IPs for homelab services (thanks to Pi-hole subnet routing)

### Access targets

| Service | URL (via Tailscale) | Notes |
|---------|---------------------|-------|
| Pi-hole admin | `http://pi-hole.bruno-ts.ts.net/admin` | DNS management |
| Media Server | `http://192.168.x.x:8096` | Jellyfin (via Pi-hole subnet) |
| Hermes dashboard | `http://vps.bruno-ts.ts.net:9119` | Requires VPS Tailscale |
| Gitea (TS) | `http://vps.bruno-ts.ts.net:3000` | If on Tailscale net |
| Android Server | `http://192.168.x.x:xxxx` | Via Pi-hole subnet |

### Tips

- **Split DNS** (optional): set Tailscale to only route tailnet traffic, so
  regular browsing still uses your 4G directly
- **Battery**: Tailscale on Android is negligible — uses WireGuard, not OpenVPN
- **Autoconnect**: the app reconnects automatically when you leave home WiFi

---

## 4. Verify end-to-end

From phone on 4G (Tailscale VPN on):

```
[✓] ping pi-hole.bruno-ts.ts.net
[✓] curl http://pi-hole.bruno-ts.ts.net/admin
[✓] curl http://192.168.0.50:8096    # Jellyfin via subnet
[✓] curl http://vps.bruno-ts.ts.net:9119    # Hermes dashboard
```

---

## Useful commands

```bash
tailscale status                    # list connected devices
tailscale ping <hostname>           # test direct connection
tailscale ip -4                     # show this device's Tailscale IP
tailscale netcheck                  # NAT / connectivity check
tailscale serve --bg --https=443 localhost:8080    # expose local port on TS
```
