# Android Server (Termux)

Android device running Termux as a homelab server.

Acts as secondary DNS for Pi-hole redundancy (see [Services](#services) and [DNS](#dns)).

## Installation

Two routes depending on whether you have a computer handy.

### With a computer

1. **Install Termux** — [F-Droid](https://f-droid.org/packages/com.termux/) (recommended, avoids Play Store issues).
   Run `termux-setup-storage` to grant file access (required on Android 11+).

2. **Install SSH server** — `pkg add openssh && sshd` (default port 8022).
   First run `passwd` to set a login password — Termux starts with none.

3. **Access via SSH** — `ssh -p 8022 <user>@<android-ip>` from your computer.
   Find the device IP with `ip addr` or `ifconfig`.

4. **Clone the repo** — `git clone https://github.com/brunodles/dotfiles.git ~/dotfiles`

5. **Run bootstrap** — `cd ~/dotfiles && bash hosts/android_server/bootstrap.sh`

### Without a computer (paste block)

Paste the following directly into Termux after installation:

```bash
pkg update -y && pkg install -y git curl
git clone https://github.com/brunodles/dotfiles.git ~/dotfiles
cd ~/dotfiles && bash hosts/android_server/bootstrap.sh
```

The bootstrap runs three phases — install (packages, Oh My Zsh, SSH keys), configure (Termux settings, scripts, SSH config), and links (dotfiles symlinks, runit services).

## Services

Services are managed via **runit** (termux-services).

| Service | Port | Path | Status |
|---------|------|------|--------|
| `sshd` | 8022 | `var/service/sshd/run` | ✅ Enabled by bootstrap |
| `ttsd` | dynamic | `var/service/ttsd/run` | ✅ Enabled by bootstrap |
| `unbound` | 53 | — | ⏸️ Commented (see [DNS](#dns)) |

```bash
sv status <service>     # check status
sv up <service>         # start
sv down <service>       # stop
sv restart <service>    # restart
sv-enable <service>     # enable on boot
sv-disable <service>    # disable on boot
```

The run scripts live in `var/service/<name>/run` within this directory.

## DNS (Unbound)

This device can act as a redundant DNS forwarder when the Pi-hole is unreachable (e.g. power outage).

The config file is at `dns/unbound.conf` — it forwards queries to the Pi-hole by default and falls back to Cloudflare DNS-over-TLS.

To enable:

```bash
pkg install unbound
cp $PREFIX/etc/unbound/unbound.conf $PREFIX/etc/unbound/unbound.conf.bak  # backup default
cp ~/dotfiles/hosts/android_server/dns/unbound.conf $PREFIX/etc/unbound/unbound.conf
sv-enable unbound
sv up unbound
```

To test:

```bash
dig @localhost google.com           # local resolution
dig @<android-ip> google.com        # from another host
unbound-control stats               # cache hit ratio
```

Update your router DHCP to set this device's IP as secondary DNS.

## Utilities

Custom scripts installed to `~/.local/bin/` during bootstrap:

| Script | Description | Example |
|--------|-------------|---------|
| `termux-wake` | Acquire CPU wakelock | `termux-wake homelab` |
| `termux-sleep` | Release wakelock | `termux-sleep homelab` |
| `termux-notify` | Send Android notification | `termux-notify -t "Alert" -c "Server is down"` |
| `termux-battery-status` | Show battery info | `termux-battery-status --alert-threshold 15` |
| `termux-ip` | Show local and public IP | `termux-ip --local -4` |
| `termux-ssh-tunnel` | Reverse SSH tunnel | `termux-ssh-tunnel --host gateway.local` |
| `termux-tts-server` | HTTP TTS server | Run as runit service (see below) |

### TTS (Text-to-Speech)

The `termux-tts-server` endpoint speaks text through the device speaker.
Managed as a runit service (`ttsd`, port stored in `~/.termux/ttsd-port`).

```bash
# Speak a message
curl -X POST http://<android-ip>:<port>/tts \
  -H "Content-Type: application/json" \
  -d '{"text": "Alerta no servidor"}'

# Find the port
cat ~/.termux/ttsd-port

# Service management
sv status ttsd
sv restart ttsd
```

## Termux Properties & Aliases

The bootstrap applies a custom `termux.properties` with:

- Extra keys row: `ESC`, `/`, `|`, `-`, `_`, `~`, `TAB` (top row) + `CTRL`, `ALT`, `FN` + arrows (bottom row)
- Dark theme (`use-black-ui = true`)
- Vibration disabled on back key

After bootstrap, the following aliases are available in Zsh:

```bash
wake       → termux-wake
sleep      → termux-sleep
notify     → termux-notify
battery    → termux-battery-status
myip       → termux-ip
tunnel     → termux-ssh-tunnel
svstart    → sv up
svstop     → sv down
svstatus   → sv status
```

Source files: `termux/termux.properties` and `home/.local/bin/` in this directory.
