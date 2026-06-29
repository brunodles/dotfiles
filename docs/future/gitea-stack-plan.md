# Gitea Stack — VPS Production Readiness

**Status:** ⏸️ Saved for later. Stack skeleton exists at `hosts/vps/dockge/stacks/gitea/`.

## O que já existe

```
hosts/vps/dockge/stacks/gitea/
├── compose.yaml        # Postgres 16 + Gitea (funcional, mas sem Traefik)
├── .env.example        # Só GITEA_DB_PASSWORD
├── README.md           # Setup manual
└── config/.keep
```

## Problemas atuais

| Item | Problema | Impacto |
|------|----------|---------|
| Porta 3000 exposta | `ports: "3000:3000"` aberta pro host | Gitea acessível na internet (se UFW falhar) |
| ROOT_URL = localhost | Traefik não roteia | Só acessa via IP:porta, sem TLS |
| Sem labels Traefik | Nenhum middleware | Sem rate-limit, auth, SSL |
| Sem script de setup | README diz pra fazer manual | Propenso a erro |
| Sem backup automático | Só comentário no README | Risco de perda de dados |
| HERMES não integrado | README mostra `git remote add gitea` | Sem script de init |

## Plano de implementação

### Fase 1 — Core (Traefik + Port Security)

- Adicionar labels Traefik no `compose.yaml` (routers, middleware, TLS)
- Remover `ports: "3000:3000"` ou bind para `127.0.0.1:3000:3000`
- Ajustar `ROOT_URL` e `DOMAIN` para o subdomínio Traefik
- Configurar `GITEA__server__PROTOCOL=https`
- Testar `docker compose up -d` + acesso via subdomínio

### Fase 2 — Scripts de Setup

- `scripts/gitea-setup.sh`:
  - Cria admin user
  - Cria hermes user + PAT
  - Cria repositórios: `dotfiles`, `hermes-plans`, `hermes-queue`
  - Configura webhook de sync (se houver home Gitea)
- `scripts/gitea-health.sh`:
  - Verifica se Gitea está respondendo
  - Verifica se o banco responde

### Fase 3 — Backup Automático

- `scripts/gitea-backup.sh`:
  - `pg_dump -U gitea gitea > backup.sql`
  - `docker compose exec gitea gitea dump` (inclui repos, config, keys)
  - Rsync para home NAS (via Tailscale)
  - Compactar com data no nome do arquivo
- Cron diário via Hermes ou cron do host

### Fase 4 — Integração Hermes

- `scripts/gitea-hermes-init.sh`:
  - Configura git remoto no volume da Hermes
  - Gera/chave PAT para autenticação
  - Testa push/pull via Docker network (`http://gitea:3000`)
- Atualizar `docs/future/gitea-hermes-infra.md` com detalhes de implementação

### Fase 5 — Monitoramento

- Traefik middleware: rate-limit, IP whitelist (Tailscale IPs)
- Healthcheck endpoint no `compose.yaml`
- Notificação Hermes se Gitea cair

## Referências

- Design original: `docs/agent-queue-design.md`
- Hermes feasibility: `docs/future/agent-queue-feasibility.md`
- Análise Gitea-Hermes: `docs/future/gitea-hermes-infra.md`
- Stack atual: `hosts/vps/dockge/stacks/gitea/`
