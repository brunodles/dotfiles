#!/bin/bash
# setup.sh — WireGuard VPN setup for VPS + Pi-hole + Phone
#
# Usage:
#   1. Edit .env or compose.yaml to set SERVERURL
#   2. docker compose up -d
#   3. ./setup.sh
#
set -euo pipefail

NS="wireguard"
SERVER_IP="${1:-}"
IMAGE="linuxserver/wireguard:latest"

echo "═══ WireGuard VPN Setup ═══"
echo ""

# ── 1. Check SERVERURL ──────────────────────────────────────
if [ -z "$SERVER_IP" ]; then
  # Try to get from compose / env
  SERVER_IP="auto"
fi

echo "Server IP/URL: $SERVER_IP"
echo ""

# ── 2. Start container ──────────────────────────────────────
if ! docker ps --format '{{.Names}}' | grep -q "^${NS}$"; then
  echo "▶ Starting WireGuard container..."
  docker compose up -d
  # Wait for config generation
  sleep 3
fi

# ── 3. Show peer configs ─────────────────────────────────────
echo "═══════════════════════════════════════════════"
echo "  PHONE CONFIG"
echo "  (open in WireGuard app on Android)"
echo "═══════════════════════════════════════════════"
docker exec "${NS}" /app/show-peer phone
echo ""

echo "═══════════════════════════════════════════════"
echo "  PI-HOLE CONFIG"
echo "  (copy to /etc/wireguard/wg0.conf on Pi-hole)"
echo "═══════════════════════════════════════════════"
docker exec "${NS}" /app/show-peer pihole
echo ""

# ── 4. Customize AllowedIPs for phone ────────────────────────
echo ""
echo "────────────────────────────────────────────────"
echo "  POST-SETUP: Customize AllowedIPs"
echo "────────────────────────────────────────────────"
echo ""
echo "The auto-generated config gives each peer only its WG IP."
echo "You need to add Docker + homelab ranges to the phone peer."
echo ""
echo "Edit /config/wg0.conf on the VPS and add to [Peer] \"phone\":"
echo "  AllowedIPs = 10.0.0.2/32, 172.16.0.0/12, 192.168.0.0/24"
echo ""
echo "Then apply:"
echo "  docker exec ${NS} apk add --no-cache iptables ip6tables"
echo "  docker exec ${NS} wg-quick down wg0 && wg-quick up wg0"
echo ""

# ── 5. Pi-hole routing ───────────────────────────────────────
echo "────────────────────────────────────────────────"
echo "  PI-HOLE: Enable routing"
echo "────────────────────────────────────────────────"
echo ""
echo "SSH into Pi-hole and enable forwarding + masquerade:"
echo ""
echo "  1. sysctl net.ipv4.ip_forward=1"
echo "  2. Add to /etc/wireguard/wg0.conf [Interface]:"
echo "     PostUp = iptables -A FORWARD -i wg0 -j ACCEPT"
echo "     PostUp = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE"
echo "     PostDown = iptables -D FORWARD -i wg0 -j ACCEPT"
echo "     PostDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE"
echo "  3. Restart: wg-quick down wg0 && wg-quick up wg0"
echo ""
echo "After this, phone → VPS → Pi-hole → homelab LAN works."
echo ""

# ── 6. Verify ────────────────────────────────────────────────
echo "────────────────────────────────────────────────"
echo "  CONNECTIONS"
echo "────────────────────────────────────────────────"
docker exec "${NS}" wg show
echo ""
echo "✅ Done."
