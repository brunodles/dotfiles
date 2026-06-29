# Pi — Raspberry Pi (Pi-hole)

Raspberry Pi running Pi-hole for DNS-level ad blocking,
connected to the homelab via Tailscale.

## Services

| Service | Role |
|---------|------|
| **Pi-hole** | DNS sinkhole — blocklist-based ad blocking + local DNS |
| **Tailscale** | Mesh VPN — reach the Pi from anywhere via 100.x.x.x |
| **DNS** | Local DNS resolution for the entire tailnet |

## Setup

```bash
git clone https://github.com/brunodles/dotfiles.git
cd dotfiles
bash hosts/pi/bootstrap.sh
```

After bootstrap completes:

```bash
sudo tailscale up              # Authenticate to tailnet
pihole -a -p                   # Set admin password
```

## Tailnet DNS

Once the Pi is on Tailscale, set the Pi-hole IP as the tailnet's
global nameserver in the Tailscale admin console. Every device on
the tailnet gets ad-blocking automatically — even phones on mobile
data.

## Recovery

If the Pi needs to be rebuilt:

```bash
git clone <repo>
bash hosts/pi/bootstrap.sh

# Restore saved config
bash hosts/pi/pihole/scripts/restore-config.sh
```

## Extraction

If you already have a running Pi-hole elsewhere:

```bash
bash hosts/pi/pihole/scripts/extract-config.sh pi@<ip>
```

This saves `setupVars.conf`, `adlists.list`, `whitelist.txt`,
`blacklist.txt`, `regex.list`, and `custom.list` into
`pihole/extracted/`.
