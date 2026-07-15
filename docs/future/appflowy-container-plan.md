# AppFlowy Container — Feasibility Plan

> **For Hermes:** Feasibility study + stack plan.

**Goal:** Evaluate self-hosting AppFlowy (open-source Notion alternative) on the media server, and determine whether it's worth the complexity for document creation.

---

## Q: What is AppFlowy?

AppFlowy is the leading open-source Notion alternative. It provides:

- Documents (rich text, markdown, databases)
- Wikis / knowledge bases
- Kanban boards, calendars, spreadsheets
- Real-time collaboration (guest editors)
- AI assistant (optional, requires OpenAI key)
- Web + Flutter (desktop/mobile) clients

The self-hosted backend is **AppFlowy Cloud** — a Rust-based service with PostgreSQL, Redis, MinIO, and a GoTrue auth server.

---

## Architecture

| Service | Image | Function |
|---------|-------|----------|
| `nginx` | nginx | Reverse proxy (TLS termination, route fan-out) |
| `postgres` | pgvector/pgvector:pg16 | Metadata, documents, user data |
| `redis` | redis | Caching, pub/sub for real-time sync |
| `minio` | minio/minio | S3-compatible object storage (images, attachments) |
| `gotrue` | appflowyinc/gotrue | Authentication (Supabase GoTrue fork) |
| `appflowy_cloud` | appflowyinc/appflowy_cloud | Core backend API (Rust) |
| `appflowy_web` | appflowyinc/appflowy_web | Web frontend |
| `appflowy_ai` | appflowyinc/appflowy_ai | AI features (optional, needs OpenAI key) |
| `appflowy_worker` | appflowyinc/appflowy_worker | Async background jobs |
| `appflowy_search` | appflowyinc/appflowy_search | Full-text search indexer |
| `admin_frontend` | appflowyinc/admin_frontend | Admin panel UI |

**Total: 11 containers** (or 10 without AI).

---

## Licensing & Cost

AppFlowy Cloud is **open-core** (not fully open-source):

| Tier | Price | Users | Guests | Features |
|------|-------|-------|--------|----------|
| **Free** | $0 | 1 user | 3 guest editors | Web app, publish pages, unlimited workspaces |
| **Team** | Paid | Multi-user | Unltd | Admin panel, audit logs, priority support |
| **Enterprise** | Paid | Unltd | Unltd | SSO, SAML, SLA |

The open-source repo is at `github.com/AppFlowy-IO/AppFlowy-Cloud`. The commercial fork adds closed-source extensions under a separate license.

**For a single-user setup:** the Free tier covers everything needed. No payment required.

---

## Resource Profile

| Component | RAM estimate |
|-----------|-------------|
| postgres (pgvector) | ~256MB |
| redis | ~32MB |
| minio | ~128MB (idle), grows with data |
| gotrue | ~64MB |
| appflowy_cloud | ~256MB |
| appflowy_web | ~128MB |
| appflowy_ai | ~128MB (idle, spikes with queries) |
| appflowy_worker | ~128MB |
| appflowy_search | ~256MB (heavy on RAM for keyword indexes) |
| admin_frontend | ~64MB |
| nginx | ~32MB |
| **Total** | **~1.5GB (idle) — ~3GB under load** |

The search service has a `APPFLOWY_KEYWORD_INDEX_MAP_SIZE_BYTES` default of 2GB — that's **mmap'd**, not RSS, but worth noting.

---

## Options

### Option A: Full AppFlowy Cloud (recommended for evaluation)

Full 11-container stack. All features, real-time sync, collaboration, search, AI.

**Pros:**
- Complete Notion replacement
- Web UI works in any browser
- Real-time collaboration
- AI assistant (with OpenAI key)
- Active development (73k+ GitHub stars)

**Cons:**
- Heavy — 10-11 containers, ~1.5-3GB RAM
- Open-core — future features may gate behind paid tiers
- Complex initial setup (GoTrue, MinIO, env vars)
- SMTP required for user management (or `GOTRUE_MAILER_AUTOCONFIRM=true`)

### Option B: Core only (skip AI + search)

Drop `appflowy_ai`, `appflowy_search`, `appflowy_worker` from the stack. Saves ~500MB RAM and reduces complexity.

**Pros:**
- Lighter (~8 containers, ~1-2GB RAM)
- Less surface area for failures

**Cons:**
- No AI assistant
- No full-text search
- No background jobs (file imports, email)

### Option C: Skip AppFlowy, use what exists

The VPS already runs Vikunja (tasks), and could use Jekyll/static for docs. True Notion-like databases and rich documents are the gap.

**Pros:**
- Zero new infrastructure
- No maintenance burden

**Cons:**
- No solution for rich documents / wikis
- Vikunja handles tasks but not documents

---

### Comparison

| Aspect | Option A (Full) | Option B (Core) | Option C (Skip) |
|--------|:---------------:|:----------------:|:----------------:|
| Containers | 11 | 8 | 0 |
| RAM idle | ~1.5GB | ~1GB | 0 |
| Documents | ✅ Full | ✅ Full | ❌ |
| Databases | ✅ | ✅ | ❌ |
| AI assistant | ✅ | ❌ | ❌ |
| Full-text search | ✅ | ❌ | ❌ |
| Real-time collab | ✅ (up to 3 guests) | ✅ | ❌ |
| SMTP needed | ⚠️ | ⚠️ | N/A |
| Maintenance | High | Medium | None |
| Cost (self-host) | Free tier works | Free tier works | N/A |

---

## Recommended approach: Option B (Core), start without AI

### Stack plan

```
stacks/appflowy/
├── compose.yaml
├── .env.example
├── config/
│   └── nginx/
│       └── nginx.conf
├── data/
│   ├── postgres/
│   │   └── .gitkeep
│   ├── minio/
│   │   └── .gitkeep
│   └── search/
│       └── .gitkeep
└── README.md
```

### Key compose structure

```yaml
services:
  postgres:
    image: pgvector/pgvector:pg16
    # pgvector needed by AppFlowy
    healthcheck: pg_isready
    volumes: [postgres_data:/var/lib/postgresql/data]
    networks: [appflowy_internal, vps_net]

  redis:
    image: redis:7-alpine
    networks: [appflowy_internal]

  minio:
    image: minio/minio
    # S3-compatible storage for uploads
    volumes: [minio_data:/data]
    networks: [appflowy_internal]

  gotrue:
    image: appflowyinc/gotrue:latest
    # Auth — Supabase GoTrue fork
    depends_on: [postgres]
    networks: [appflowy_internal]

  appflowy_cloud:
    image: appflowyinc/appflowy_cloud:latest
    # Core Rust backend
    depends_on: [gotrue, postgres, redis]
    healthcheck: curl /api/health
    networks: [appflowy_internal]

  appflowy_web:
    image: appflowyinc/appflowy_web:latest
    # Web frontend
    depends_on: [appflowy_cloud]
    networks: [proxy, appflowy_internal]
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.appflowy.rule=Host(`appflowy.lab`)"
      - "traefik.http.routers.appflowy.entrypoints=web"
      - "traefik.http.services.appflowy.loadbalancer.server.port=80"

networks:
  proxy:
    external: true
  appflowy_internal:
    driver: bridge
  vps_net:
    name: vps_net
    external: true

volumes:
  postgres_data:
  minio_data:
  keyword_index_data:
```

**Notes:**
- The official compose uses nginx as reverse proxy in front of AppFlowy. With Traefik handling routing, nginx can be dropped — Traefik routes directly to `appflowy_web:80`.
- MinIO is on `vps_net` so other stacks could theoretically use it, but for simplicity it stays on `appflowy_internal` only.
- The `appflowy_web` container runs its own HTTP server (not nginx in this image). Traefik routes `appflowy.lab` → it.

### Environment (.env.example)

```bash
# ── AppFlowy Cloud — env vars

# PostgreSQL
POSTGRES_USER=postgres
POSTGRES_PASSWORD=changeme
POSTGRES_DB=postgres
POSTGRES_PORT=5432

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# MinIO / S3
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=changeme
AWS_ACCESS_KEY=minioadmin
AWS_SECRET=changeme

# GoTrue (Auth)
GOTRUE_ADMIN_EMAIL=admin@lab
GOTRUE_ADMIN_PASSWORD=changeme
GOTRUE_JWT_SECRET=changeme
GOTRUE_MAILER_AUTOCONFIRM=true         # skip email confirmation
GOTRUE_DISABLE_SIGNUP=true             # single-user, no open signup
GOTRUE_SMTP_HOST=
GOTRUE_SMTP_PORT=
GOTRUE_SMTP_USER=
GOTRUE_SMTP_PASS=

# AppFlowy Cloud
APPFLOWY_BASE_URL=http://appflowy.lab
APPFLOWY_DATABASE_URL=postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:${POSTGRES_PORT}/${POSTGRES_DB}
APPFLOWY_REDIS_URI=redis://redis:${REDIS_PORT}
APPFLOWY_GOTRUE_BASE_URL=http://gotrue:9999
APPFLOWY_S3_USE_MINIO=true
APPFLOWY_S3_ACCESS_KEY=${AWS_ACCESS_KEY}
APPFLOWY_S3_SECRET_KEY=${AWS_SECRET}
APPFLOWY_S3_BUCKET=appflowy
APPFLOWY_S3_REGION=us-east-1
APPFLOWY_S3_MINIO_URL=http://minio:9000
APPFLOWY_S3_PRESIGNED_URL_ENDPOINT=http://appflowy.lab/api
```

---

## Risks & open questions

- **Open-core licensing** — the Free tier is generous enough for single-user, but the project could gate future features behind paid tiers. The open-source repo is MIT/Apache (AppFlowy client) and AGPL (AppFlowy Cloud), but the commercial fork has a separate license. Need to read the fine print before depending on it.
- **SMTP is optional** with `GOTRUE_MAILER_AUTOCONFIRM=true`, but some flows (password reset, invite) still need it. Without SMTP, those features are broken.
- **11 containers is heavy for the media server.** The media server currently runs Jellyfin, Syncthing, MeTube — adding AppFlowy + Postgres + Redis + MinIO + 7 AppFlowy-specific services is a significant jump.
- **Backup strategy.** Postgres, MinIO data, and keyword indexes all need backup. Same as other DB stacks, but MinIO needs S3-native backup or filesystem snapshots.
- **Real-time sync requires WebSocket support** in Traefik. The `appflowy_web` WS endpoint needs `traefik.http.middlewares.appflowy-websocket.stripprefix.prefixes=/ws/v2` or similar pass-through — Traefik handles WebSocket transparently by default, so this may work out of the box.
- **Pricing page requires login.** The official pricing table is behind a login wall. The user needs to visit `appflowy.com/pricing` to see current self-hosted tiers.

---

## Decision

| Priority | Option | Complexity | Value | Decision |
|----------|--------|:----------:|:-----:|:--------:|
| 1 | **AppFlowy Core** (no AI/search) | Medium | High | 🟡 Evaluate first — check licensing + RAM budget |
| 2 | Full AppFlowy | High | High | ❌ Too heavy for current media server specs |
| 3 | Skip — use existing tools | None | Medium | 🟢 Already works for tasks; documents are the gap |

**Recommended first step:** Deploy a minimal AppFlowy test instance (core without AI/search) under `stacks/appflowy/` on the media server. Evaluate:
1. RAM usage in practice (check vs estimate)
2. Whether the Free tier restrictions matter for single-user
3. Whether documents/databases fill the Notion gap
4. Whether the WebSocket + Traefik combo works for real-time

---

## Files to create

| File | Content |
|------|---------|
| `stacks/appflowy/compose.yaml` | Docker Compose (8 services, no nginx, Traefik routing) |
| `stacks/appflowy/.env.example` | Env vars |
| `stacks/appflowy/README.md` | Setup and access docs |
| `stacks/appflowy/data/` | Persistent data dirs (postgres, minio, search) |
| `scripts/dns/dns-config.yaml` | Add `appflowy.lab` record |
| `docs/current-state.md` | Update stacks tree |
| `hosts/media/bootstrap/provision.sh` | Add to symlink loop |
