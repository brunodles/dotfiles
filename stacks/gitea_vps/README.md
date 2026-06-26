# Gitea VPS

Gitea self-hosted na VPS, roteado via Traefik, banco SQLite.

## Deploy

```bash
# 1. Subir o stack
cd stacks/gitea_vps
docker compose up -d

# 2. Rodar setup (cria admin, hermes, repos)
bash setup.sh
```

## Acesso

| Rota | URL |
|------|-----|
| Traefik | `http://gitea.lab` |
| Docker internal | `http://gitea:3000` |

## Setup manual (sem setup.sh)

```bash
docker compose exec -T gitea gitea admin user create \
  --username bruno --password <senha> --email bruno@lab --admin

docker compose exec -T gitea gitea admin user create \
  --username hermes --password <senha> --email hermes@vps
```

## Config

Tudo via variáveis de ambiente no compose:

| Variável | Valor | Efeito |
|----------|-------|--------|
| `INSTALL_LOCK` | `true` | Pula instalador web |
| `DISABLE_REGISTRATION` | `true` | Só admin cria users |
| `DISABLE_SSH` | `true` | HTTP-only |
| `ROOT_URL` | `http://gitea.lab/` | Base pro Traefik |
