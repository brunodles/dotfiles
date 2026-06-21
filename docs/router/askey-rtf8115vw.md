# Askey RTF8115VW — Router Guide

> ISP: Vivo (Brazil) · Modem/Router/ONT combo · GPON

## Access

| Interface | Address | Credentials | Purpose |
|-----------|---------|-------------|---------|
| Web admin | `http://192.168.15.1` | User: `admin` / Pass: sticker | General settings, DNS, DHCP |
| Web advanced | `http://192.168.15.1/padrao/` | Same as above | Hidden advanced config page |
| SSH | `ssh support@192.168.15.1` | Pass: sticker | Linux shell + ASPSH |

## SSH Access

```bash
ssh support@192.168.15.1
# password from device sticker

# Available commands once logged in:
sh          → Linux shell
aspsh       → ASPSH environment (persistent firewall rules)
reboot      → Reboots the router
```

### ASPSH

ASPSH is the router's configuration shell. It stores settings in NVRAM,
making them survive reboots.

```aspsh
# Enter ASPSH environment
aspsh

# Example: add a firewall rule
set firewall_rule add name=default interface=wan type=out default_action=permit

# List rules
show firewall_rule

# Exit
exit
```

> **Note:** ASPSH commands for DHCP/DNS are not well documented.
> See the web API below for DNS changes.

## DNS Update via HTTP API (Recommended)

The router exposes an HTTP API that can be automated with `curl`.

### Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/login.asp` | GET | Obtain session cookie |
| `/cgi-bin/te_acceso_router.cgi` | POST | Authenticate (`loginUsername`, `loginPassword`) |
| `/te_red_local.asp` | POST | Update DNS (`DNSserver1`, `DNSserver2`, `Password`) |
| `/padrao/` | GET | Advanced settings page |

### Usage

```bash
PASSWORD=<admin_pass> bash scripts/router/update-dns.sh 192.168.1.53

# With secondary DNS:
PASSWORD=<admin_pass> bash scripts/router/update-dns.sh 192.168.1.53 192.168.1.54

# Custom router IP:
PASSWORD=<admin_pass> ROUTER=10.0.0.1 bash scripts/router/update-dns.sh 192.168.1.53
```

## Community References

| Repository | Description | Key Insights |
|------------|-------------|--------------|
| [edgardocorrea/modem-vivo](https://github.com/edgardocorrea/modem-vivo) | Unlock tool (Node.js + Selenium) | Revealed **HTTP API endpoints**: `/login.asp` → cookie → `/cgi-bin/te_acceso_router.cgi` |
| [rogocal/movistar-router-automatizer](https://github.com/rogocal/movistar-router-automatizer) | DNS automation (Python + Selenium) | Confirmed **DNS page**: `/te_red_local.asp`, fields `DNSserver1`, `DNSserver2` |
| [superMDMArio/RTF8115VW](https://github.com/superMDMArio/RTF8115VW) | Firewall via ASPSH guide | Documented **SSH access** + **ASPSH** environment for persistent firewall rules |
| [abandonedship/movistar_router_RTF8115VW_admin_panel_password_decrypt](https://github.com/abandonedship/movistar_router_RTF8115VW_admin_panel_password_decrypt) | Password decrypt tool | Router uses simple XOR for web password (POC only) |

## Notes

- The router firmware is locked by Vivo — no OpenWrt replacement available.
- SSH password is the **same sticker password** used for web admin.
- The web API endpoints were found by reverse-engineering the Selenium unlock
  tool (`modem-vivo`). They are stable across firmware versions but could
  change if Vivo pushes an update.
- After running `update-dns.sh`, verify the changes stick by checking
  `http://192.168.15.1/te_red_local.asp` or the advanced page at `/padrao/`.
- If DNS resets after a reboot, re-run the script or set up a cron job.
- For long-term persistence, investigate if DNS settings can be committed via
  ASPSH (currently undocumented — needs exploration via SSH).
