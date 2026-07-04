#!/usr/bin/env bash
# apply-dns.sh — Aplica dns-config.yaml nos hosts do homelab
#
# Lê scripts/dns/dns-config.yaml e:
#   - Android: gera dnsmasq.conf → scp → sv restart dnsmasq
#   - Pi:      gera 99-homelab.conf → scp → pihole restartdns
#
# Uso:
#   ./apply-dns.sh                    # ambos os hosts
#   ./apply-dns.sh --host android     # só android
#   ./apply-dns.sh --host pi          # só pi
#   ./apply-dns.sh --dry-run          # mostra o que faria, sem executar
#
# Dependências: yq (parse YAML), ssh, scp
#   pkg install yq  (Android/Termux)
#   apt install yq  (Debian/Ubuntu)
#
set -euo pipefail

# ── Config ──────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Config: use real file first, fall back to example
CONFIG_FILE="${CONFIG_FILE:-$SCRIPT_DIR/dns-config.yaml}"
EXAMPLE_FILE="$SCRIPT_DIR/dns-config.example.yaml"
if [ ! -f "$CONFIG_FILE" ] && [ -f "$EXAMPLE_FILE" ]; then
  CONFIG_FILE="$EXAMPLE_FILE"
  info "No dns-config.yaml found, using example file."
  info "Copy it to add real MACs:"
  info "  cp $EXAMPLE_FILE $SCRIPT_DIR/dns-config.yaml"
  echo
fi

# Hosts alvo (SSH via Tailscale — ajustar IPs/hostnames)
ANDROID_SSH="${ANDROID_SSH:-android.lab}"
ANDROID_SSH_PORT="${ANDROID_SSH_PORT:-8022}"
ANDROID_DNSMASQ_CONF="/data/data/com.termux/files/usr/etc/dnsmasq.conf"

PI_SSH="${PI_SSH:-pi.lab}"
PI_SSH_PORT="${PI_SSH_PORT:-22}"
PI_DNSMASQ_DIR="/etc/dnsmasq.d"
PI_HOMELAB_CONF="99-homelab.conf"

DOMAIN="lab"

# ── Help ─────────────────────────────────────────
usage() {
  sed -n '2,/^$/s/^# \?//p' "$0"
  exit 0
}

# ── Helpers ──────────────────────────────────────
die() { echo "✖ $*" >&2; exit 1; }
info() { echo "➜ $*"; }
ok()   { echo "  ✅ $*"; }
skip() { echo "  ⏭️  $*"; }

require_yq() {
  if ! command -v yq &>/dev/null; then
    die "yq not found. Install: https://github.com/mikefarah/yq"
  fi
}

# ── Parse YAML ───────────────────────────────────
parse_config() {
  require_yq

  # Validação básica
  [[ -f "$CONFIG_FILE" ]] || die "Config not found: $CONFIG_FILE"

  # Extrai valores do YAML via yq

  # Primary upstream
  PRIMARY=$(yq '.upstream.primary' "$CONFIG_FILE")
  [[ -n "$PRIMARY" ]] || die "upstream.primary is required"

  # Fallbacks
  FALLBACKS=$(yq '.fallback[]' "$CONFIG_FILE" 2>/dev/null || echo "")

  # Local domains
  LOCAL_DOMAINS=$(yq '.local_domains[]' "$CONFIG_FILE" 2>/dev/null || echo "")

  # Static hosts
  HOSTS_COUNT=$(yq '.hosts | length' "$CONFIG_FILE")

  # CNAMEs
  CNAMES_COUNT=$(yq '.cnames | length' "$CONFIG_FILE")

  # DHCP
  DHCP_ENABLED=$(yq '.dhcp.enabled // false' "$CONFIG_FILE")
}

# ── Gerar config ─────────────────────────────────

# Gera config para o Android (dnsmasq.conf completo)
generate_android_config() {
  local out="$1"

  cat > "$out" <<CONF
# ──────────────────────────────────────────────
# dnsmasq.conf — Gerado por apply-dns.sh
# Fonte: scripts/dns/dns-config.yaml
# AVISO: Editado manualmente será sobrescrito!
# ──────────────────────────────────────────────

port=53
interface=0.0.0.0
bind-interfaces

# ── Upstreams ──
server=$PRIMARY
CONF

  # Fallbacks
  while IFS= read -r fb; do
    [[ -z "$fb" ]] && continue
    echo "server=$fb" >> "$out"
  done <<< "$FALLBACKS"

  cat >> "$out" <<'CONF'

# ── Domínios locais ──
CONF

  while IFS= read -r ld; do
    [[ -z "$ld" ]] && continue
    echo "local=/$ld/" >> "$out"
  done <<< "$LOCAL_DOMAINS"

  cat >> "$out" <<'CONF'

# ── Hosts estáticos (DNS) ──
CONF

  for i in $(seq 0 $((HOSTS_COUNT - 1))); do
    name=$(yq ".hosts[$i].name" "$CONFIG_FILE")
    ip=$(yq ".hosts[$i].ip" "$CONFIG_FILE")
    aliases=$(yq ".hosts[$i].aliases[]" "$CONFIG_FILE" 2>/dev/null || echo "")

    # A record: address=/<name>.lab/<ip>
    echo "address=/${name}.$DOMAIN/$ip" >> "$out"

    # Aliases (CNAME-like via address=)
    while IFS= read -r alias; do
      [[ -z "$alias" ]] && continue
      echo "address=/${alias}.$DOMAIN/$ip" >> "$out"
    done <<< "$aliases"
  done

  # CNAMEs avulsos
  if [[ "$CNAMES_COUNT" -gt 0 ]]; then
    cat >> "$out" <<'CONF'

# ── CNAMEs avulsos ──
CONF
    for i in $(seq 0 $((CNAMES_COUNT - 1))); do
      alias=$(yq ".cnames[$i].alias" "$CONFIG_FILE")
      target=$(yq ".cnames[$i].target" "$CONFIG_FILE")
      echo "cname=${alias}.$DOMAIN,${target}.$DOMAIN" >> "$out"
    done
  fi

  cat >> "$out" <<'CONF'

# ── ACL ──
domain-needed
bogus-priv
expand-hosts

# Permitir consultas da LAN
# (dnsmasq escuta em 0.0.0.0 por padrão)
CONF

  # DHCP (se ativado)
  if [[ "$DHCP_ENABLED" == "true" ]]; then
    dhcp_range=$(yq '.dhcp.range // ""' "$CONFIG_FILE")
    dhcp_gateway=$(yq '.dhcp.gateway // ""' "$CONFIG_FILE")
    dhcp_dns=$(yq '.dhcp.dns // ""' "$CONFIG_FILE")
    dhcp_domain=$(yq '.dhcp.domain // ""' "$CONFIG_FILE")

    cat >> "$out" <<'CONF'

# ── DHCP ──
CONF

    [[ -n "$dhcp_range" ]] && echo "dhcp-range=$dhcp_range" >> "$out"
    [[ -n "$dhcp_gateway" ]] && echo "dhcp-option=3,$dhcp_gateway" >> "$out"
    [[ -n "$dhcp_dns" ]] && echo "dhcp-option=6,$dhcp_dns" >> "$out"
    [[ -n "$dhcp_domain" ]] && echo "domain=$dhcp_domain" >> "$out"

    # Reservas MAC→IP
    echo "" >> "$out"
    echo "# ── Reservas DHCP (MAC→IP) ──" >> "$out"
    for i in $(seq 0 $((HOSTS_COUNT - 1))); do
      mac=$(yq ".hosts[$i].mac" "$CONFIG_FILE")
      ip=$(yq ".hosts[$i].ip" "$CONFIG_FILE")
      name=$(yq ".hosts[$i].name" "$CONFIG_FILE")
      echo "dhcp-host=$mac,$ip,$name" >> "$out"
    done
  fi

  echo "" >> "$out"
  echo "# ── Fim (gerado por apply-dns.sh) ──" >> "$out"
}

# Gera config para o Pi (99-homelab.conf — só registros locais)
generate_pi_config() {
  local out="$1"

  cat > "$out" <<CONF
# ──────────────────────────────────────────────
# 99-homelab.conf — Gerado por apply-dns.sh
# Fonte: scripts/dns/dns-config.yaml
# AVISO: Editado manualmente será sobrescrito!
# ──────────────────────────────────────────────
# Pi-hole gerencia upstreams e blocklists.
# Este arquivo só adiciona registros locais.
# ──────────────────────────────────────────────

# ── Domínios locais ──
CONF

  while IFS= read -r ld; do
    [[ -z "$ld" ]] && continue
    echo "local=/$ld/" >> "$out"
  done <<< "$LOCAL_DOMAINS"

  cat >> "$out" <<'CONF'

# ── Hosts estáticos ──
CONF

  for i in $(seq 0 $((HOSTS_COUNT - 1))); do
    name=$(yq ".hosts[$i].name" "$CONFIG_FILE")
    ip=$(yq ".hosts[$i].ip" "$CONFIG_FILE")
    aliases=$(yq ".hosts[$i].aliases[]" "$CONFIG_FILE" 2>/dev/null || echo "")

    echo "address=/${name}.$DOMAIN/$ip" >> "$out"

    while IFS= read -r alias; do
      [[ -z "$alias" ]] && continue
      echo "address=/${alias}.$DOMAIN/$ip" >> "$out"
    done <<< "$aliases"
  done

  if [[ "$CNAMES_COUNT" -gt 0 ]]; then
    cat >> "$out" <<'CONF'

# ── CNAMEs avulsos ──
CONF
    for i in $(seq 0 $((CNAMES_COUNT - 1))); do
      alias=$(yq ".cnames[$i].alias" "$CONFIG_FILE")
      target=$(yq ".cnames[$i].target" "$CONFIG_FILE")
      echo "cname=${alias}.$DOMAIN,${target}.$DOMAIN" >> "$out"
    done
  fi

  echo "" >> "$out"
  echo "# ── Fim (gerado por apply-dns.sh) ──" >> "$out"
}

# ── Aplicar remoto ──────────────────────────────

apply_android() {
  local dry_run="${1:-false}"
  local tmpfile
  tmpfile=$(mktemp)

  info "Gerando config para Android..."
  generate_android_config "$tmpfile"

  info "Aplicando via SSH em $ANDROID_SSH (port $ANDROID_SSH_PORT)..."
  if $dry_run; then
  echo "  ── dnsmasq.conf que seria enviado ──"
  cat "$tmpfile"
  echo "  ── fim ──"
  info "scp -P $ANDROID_SSH_PORT $tmpfile → $ANDROID_SSH:$ANDROID_DNSMASQ_CONF"
  info "ssh -p $ANDROID_SSH_PORT $ANDROID_SSH 'sv restart dnsmasq'"
  else
  scp -P "$ANDROID_SSH_PORT" "$tmpfile" "${ANDROID_SSH}:${ANDROID_DNSMASQ_CONF}" && \
    ok "Config enviada para Android"
  ssh -p "$ANDROID_SSH_PORT" "$ANDROID_SSH" "sv restart dnsmasq 2>/dev/null || sv down dnsmasq && sv up dnsmasq" && \
    ok "dnsmasq reiniciado no Android"
  fi

  rm -f "$tmpfile"
}

apply_pi() {
  local dry_run="${1:-false}"
  local tmpfile
  tmpfile=$(mktemp)

  info "Gerando config para Pi..."
  generate_pi_config "$tmpfile"

  info "Aplicando via SSH em $PI_SSH (port $PI_SSH_PORT)..."
  if $dry_run; then
    echo "  ── $PI_HOMELAB_CONF que seria enviado ──"
    cat "$tmpfile"
    echo "  ── fim ──"
    info "scp -P $PI_SSH_PORT $tmpfile → $PI_SSH:$PI_DNSMASQ_DIR/$PI_HOMELAB_CONF"
    info "ssh -p $PI_SSH_PORT $PI_SSH 'pihole restartdns'"
  else
    scp -P "$PI_SSH_PORT" "$tmpfile" "${PI_SSH}:${PI_DNSMASQ_DIR}/${PI_HOMELAB_CONF}" && \
      ok "Config enviada para Pi"
    ssh -p "$PI_SSH_PORT" "$PI_SSH" "pihole restartdns" && \
      ok "Pi-hole reiniciado"
  fi

  rm -f "$tmpfile"
}

# ── Main ─────────────────────────────────────────
main() {
  local target="both"
  local dry_run=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --host)  target="$2"; shift 2 ;;
      --dry-run) dry_run=true; shift ;;
      -h|--help) usage ;;
      *) die "Unknown option: $1" ;;
    esac
  done

  parse_config

  case "$target" in
    both)
      apply_android "$dry_run"
      apply_pi "$dry_run"
      ;;
    android)
      apply_android "$dry_run"
      ;;
    pi)
      apply_pi "$dry_run"
      ;;
    *)
      die "Unknown target: $target (use android, pi, or both)"
      ;;
  esac

  echo ""
  ok "DNS config applied to $target"
}

main "$@"
