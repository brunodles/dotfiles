# Tailscale

Tailscale sidecar for the VPS. Joins the tailnet so VPS services
can reach other homelab devices (Pi-hole for DNS, Android/Termux
for SSH, etc.) without exposing anything to the public internet.

## Usage

### 1. Generate an auth key

Go to https://login.tailscale.com/admin/settings/authkeys

Create a key with:
- **Tags**: `tag:vps` (or similar)
- **Ephemeral**: off (reusable, survives container restarts)
- **Pre-approved nodes**: on (no web login needed)

### 2. Set the auth key

```bash
cp .env.example .env
# Edit .env and paste your TS_AUTHKEY
```

### 3. Start the stack

```bash
docker compose up -d
```

Or via Dockge — click **Deploy** and set the `TS_AUTHKEY` environment
variable in the Dockge UI.

### 4. Verify

```bash
docker compose exec tailscale tailscale status
```

You should see the VPS listed under your tailnet (100.x.x.x).

## How other containers reach the tailnet

Containers on the `proxy` network can reach tailnet devices through the
Tailscale container as a gateway. Use the Tailscale container's
proxy-network IP as a DNS server, or set `network_mode: service:tailscale`
on any service that needs full tailnet access.

## Subnet routing (optional)

If you want other machines on the VPS's local network to be reachable
via Tailscale, add `--advertise-routes=<CIDR>` to `TS_EXTRA_ARGS`:

```yaml
environment:
  - TS_EXTRA_ARGS=--accept-dns=true --advertise-routes=10.0.0.0/24
```

Then enable subnet routing in the Tailscale admin console.
