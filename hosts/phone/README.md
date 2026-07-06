# Phone — Terminal client (Android / Termux)
#
# Android phone used as a terminal client to access homelab hosts.
# This is a **consumer** device — no services, no daemons, no dnsmasq.
# Just SSH, tmux, and a clean terminal experience.

## Installation

1. **Install Termux** — [F-Droid](https://f-droid.org/packages/com.termux/) (recommended).
2. Paste the following directly into Termux:

```bash
# grant file access (required on Android 11+)
termux-setup-storage
 
apt update -y
apt upgrade -y

pkg install -y git curl

git clone https://github.com/brunodles/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash hosts/phone/bootstrap.sh
```

The bootstrap runs three phases:
- **install** — packages, Oh My Zsh, plugins
- **configure** — Termux settings, SSH config, scripts, aliases
- **links** — dotfiles symlinks

## SSH Access

The bootstrap prompts you to generate an ED25519 key pair.
**Use a passphrase.** The phone is a mobile device — if lost, the passphrase
is all that protects your homelab servers.

Add the public key to each server:

```bash
echo 'ssh-ed25519 AAAA...' >> ~/.ssh/authorized_keys
```

The SSH config (`home/.ssh/config`) pre-configures connections to homelab
hosts via Tailscale IPs. Adjust paths in the config to match your actual
keys and addresses.

## Included Scripts

| Script | Description |
|--------|-------------|
| `termux-ip` | Show local and public IP |
| `termux-notify` | Send Android notification |
| `termux-wake` | Acquire CPU wakelock |

These live in `scripts/termux/bin/` and are copied to `~/.local/bin/`.

## Termux Config

Extra keys row (ESC, TAB, CTRL, ALT, arrows) from `scripts/termux/termux.properties`.
Zsh with Oh My Zsh, autosuggestions, syntax highlighting.

## What This Host Does NOT Have

Unlike `android_server`, the phone has:
- ❌ No SSH daemon (it connects *to* servers, not *from*)
- ❌ No runit services
- ❌ No dnsmasq / DNS
- ❌ No TTS bot
- ❌ No reverse tunnel
- ❌ No wakelock (phone can go to sleep normally)
