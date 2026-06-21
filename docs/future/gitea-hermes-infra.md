# Gitea na VPS — Hermes Agent Git Infrastructure

## Visão Geral

Análise de viabilidade de rodar uma instância Gitea dedicada na VPS para a
Hermes Agent usar como infraestrutura git primária, com sincronização opcional
para um Gitea local na rede doméstica.

Baseado em investigação: `deleg_5e9260ee` (2026-06-21).

## O que a Hermes ganharia com Gitea local

| Cenário | GitHub público | Gitea VPS local |
|---------|---------------|-----------------|
| **Fila multi-agente** | `.git-queue` sujeito a merge conflict | **Issues API** — sem conflito, atômico |
| **Docs de planejamento** | Público (vaza estratégia do agente) | Privado (repos `hermes-plans/`, `hermes-adrs/`) |
| **CI/CD** | GitHub Actions (público ou `runner` caro) | **Gitea Actions** (roda na VPS, zero custo) |
| **Configs geradas** | Traefik, compose, infra → público | Privado com versionamento |
| **Secrets** | GitHub Secrets (requer rede externa) | Gitea Actions Secrets (criptografado, local) |
| **Offline** | Depende de GitHub estar no ar | Funciona sempre |

## Três Topologias

| Topologia | Prós | Contras |
|-----------|------|---------|
| **A) Só GitHub** | Simples, grátis | Público, rate-limited, sem secrets |
| **B) Só Gitea VPS** | Autonomia total, ~0ms latência | SPOF (VPS caiu = histórico perdido) |
| **C) VPS ↔ Home (sincronizado)** | **Redundância**, backup em casa, acesso humano | Complexidade do sync |

**Recomendação:** Topologia C — VPS escreve, Home espelha (unidirecional).

## Estratégia de Sincronização (VPS → Home)

```
VPS Gitea ──post-receive hook──► Home Gitea (mirror push imediato)
    │
    └──cron a cada 10 min──► gitea dump → rsync → Home NAS
```

- **Post-receive hook:** push imediato para o mirror
- **Cron (10 min):** recovery de hooks perdidos + backup `gitea dump`
- **Home → VPS:** merge request via webhook → Hermes aprova/mergeia

## Impacto no Design da Fila (git-queue)

O atual design `scripts/git-queue` (baseado em arquivos no `.git-queue/`)
pode ser **significativamente melhorado** usando a API de Issues do Gitea:

| Atual (arquivo + flock) | Proposto (Gitea Issues API) |
|-------------------------|----------------------------|
| Arquivos JSON no `.git-queue/` | Issues REST API (`POST /repos/hermes/board/issues`) |
| `flock` POSIX lock | `PATCH /issues/1 { labels: ["in_progress"] }` |
| Merge conflict em write concorrente | **Sem conflito** — operações atômicas via API |
| Heartbeat via token file | TTL natural da sessão da API |
| Estado preso ao git DAG | Estado persistido no SQLite do Gitea |

## Recomendação Final

**✅ Seguir em frente com Gitea na VPS para Hermes.** Manter GitHub para
dotfiles públicos. O ganho real (operação offline, dados privados, fila sem
conflitos, secrets locais, CI/CD) supera a complexidade operacional.

### Roteiro de Implementação

1. Deploy Gitea na VPS (compose já existe em `hosts/vps/dockge/stacks/gitea/`)
2. Configurar Traefik route + Tailscale access
3. Criar repos `hermes-plans`, `hermes-queue`, `hermes-secrets`
4. Plugin Hermes minimal: `gitea.task.create`, `gitea.task.claim`, `gitea.task.complete`
5. Deprecate `.git-queue` file-based → migrar para Issues API
6. Setup sync VPS → Home (post-receive hook + cron)

---

**Referências cruzadas:**
- Queue design: `docs/agent-queue-design.md`
- Queue feasibility: `docs/future/agent-queue-feasibility.md`
- Gitea compose: `hosts/vps/dockge/stacks/gitea/compose.yml`
