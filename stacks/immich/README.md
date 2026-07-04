# Immich — Media Server

Self-hosted photo and video management — backup de celular, álbum familiar, organização de acervo.

## Serviços

| Serviço | Imagem | Função |
|---------|--------|--------|
| `immich-server` | `ghcr.io/immich-app/immich-server` | API + Web UI |
| `immich-machine-learning` | `ghcr.io/immich-app/immich-machine-learning` | Detecção facial (CPU) |
| `database` | `ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0` | Postgres + pgvecto.rs |
| `redis` | `valkey/valkey:9` | Fila de jobs |

## Deploy

```bash
# 1. Entrar no diretório da stack
cd stacks/immich

# 2. Copiar e configurar
cp .env.example .env
# Edite .env: DB_PASSWORD, confira os paths

# 3. Criar diretórios de dados
mkdir -p /media/data/immich/library
mkdir -p /media/data/immich/postgres

# 4. Subir
docker compose up -d
```

## Acesso

| Rota | Domínio |
|------|---------|
| Traefik (LAN) | `http://immich.lab` |
| Container | `http://immich-server:2283` |

LAN + Tailscale apenas — sem exposição pública.

## Primeiro acesso

1. Abrir `http://immich.lab`
2. Criar conta de admin (primeiro usuário vira admin automático)
3. Convidar família pela interface

## ML (Machine Learning)

Face detection ativado, CPU-only. A primeira varredura no acervo pode demorar.

Para aceleração por hardware (NVIDIA, Intel QSV, ROCm), veja:
https://docs.immich.app/features/ml-hardware-acceleration

## Upgrades

```bash
docker compose pull
docker compose up -d
```

Immich pode precisar de migração de banco — o servidor roda automaticamente na inicialização. Confira o changelog antes de versões major.

## Volumes

| Caminho (host) | Uso |
|----------------|-----|
| `/media/data/immich/library` | Uploads (fotos e vídeos originais) |
| `/media/data/immich/postgres` | Dados do banco |
| `model-cache` (named volume) | Cache dos modelos ML |

Os paths são configuráveis via `.env`.
