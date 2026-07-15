# Figma Container — Feasibility Plan

> **For Hermes:** Feasibility study + stack plan.

**Goal:** Evaluate options for self-hosting a design tool (Figma-compatible) in a container, and determine whether Hermes can produce visual sketches.

---

## Q: Hermes can create Figma sketches?

**Short answer: No.** Hermes operates via terminal, code, and text — it has no visual canvas, no mouse/pointer, and no vector rendering pipeline. Creating actual Figma files (`.fig`) with layered vector graphics requires interactive visual manipulation that Hermes cannot perform.

**What Hermes CAN do:**

| Capability | Output | How to use |
|------------|--------|------------|
| **SVG code** | Raw vector graphics | Write SVG inline or to files. Figma imports SVGs. |
| **HTML/CSS mockups** | Visual wireframes as web pages | Serve via `static.lab`. Useful for quick UI review. |
| **Figma REST API** | Programmatic frames, text, shapes | Limited — can create frame trees, set text, apply fills. No smart selection, no auto-layout logic. |
| **Text spec** | Design requirements | Markdown with dimensions, colors, spacing. Human translates to Figma. |

**Bottom line:** Hermes can produce SVG/HTML specs and basic Figma API output, but not actual visual sketches. A designer (human or AI vision model) is needed to turn specs into real Figma designs.

---

## Options for a design tool container

### Option A: Penpot (recommended)

**What it is:** Open-source design & prototyping platform. Runs in browser. Figma-compatible format (SVG-based), allows import/export.

**Pros:**
- Docker-native (official compose stack)
- Web UI — no X11, no VNC, no GPU needed
- SVG export/import
- Figma file import (experimental)
- Collaboration features (live cursors, comments)
- ACTIVE development (Mozilla-backed)

**Cons:**
- Not *actual* Figma — different UI, some features absent
- No plugin ecosystem like Figma
- Requires PostgreSQL

**Resource usage:** ~400MB RAM (backend + frontend + postgres)

### Option B: Figma web via browser

**What it is:** Just open `figma.com` in any browser. No container needed.

**Pros:**
- Zero setup
- Full Figma features
- Works behind Tailscale VPN

**Cons:**
- Requires internet access
- No self-hosting
- Depends on Figma account (free tier limited to 3 projects)
- No control over data sovereignty

### Option C: Figma desktop via Kasm Workspaces

**What it is:** Kasm runs a containerized browser that loads Figma web. Delivered as a web app with VNC.

**Pros:**
- Sandboxed browser session
- Works with Tailscale
- Session persistence

**Cons:**
- Heavy (Kasm server + browser container = 1.5GB+ RAM)
- Just wraps Figma web — same limitations
- Complex setup
- Overkill for this use case

### Option D: Figma REST API scripts

**What it is:** Hermes calls Figma's REST API to create/update .fig files programmatically.

**Pros:**
- No container needed
- Hermes can write the scripts
- Can batch-create frames, pages, text

**Cons:**
- Vector operations are VERY limited (no boolean groups, no auto layout, no components)
- Requires Figma Personal Access Token
- Still needs Figma account
- Not a replacement for the design tool itself

### Comparison

| Aspect | Penpot | Figma web | Kasm Figma | Figma API |
|--------|--------|-----------|------------|-----------|
| Self-hosted | ✅ | ❌ | ✅ (kasm) | ❌ |
| Docker-native | ✅ | ⬜ | ❌ | ⬜ |
| Web UI | ✅ | ✅ | ✅ (VNC) | ❌ |
| Offline-capable | ✅ | ❌ | ✅ (if cached) | ❌ |
| Figma file import | ⬜ (experimental) | ✅ (native) | ✅ | N/A |
| Resource usage | ~400MB | 0 | ~1.5GB | 0 |
| Hermes integrable | ⬜ (API) | ❌ | ❌ | ✅ |
| Complexity | Low | None | High | Low |

---

## Recommended approach: Penpot

### Stack plan

```
stacks/penpot/
├── compose.yaml
├── .env.example
├── config/
│   └── penpot.conf        # exporter config
└── README.md
```

### Docker compose

```yaml
services:
  penpot-frontend:
    image: penpotapp/frontend:latest
    container_name: penpot
    restart: unless-stopped
    depends_on:
      penpot-backend:
        condition: service_healthy
    networks:
      - proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.penpot.rule=Host(`penpot.lab`)"
      - "traefik.http.routers.penpot.entrypoints=web"
      - "traefik.http.services.penpot.loadbalancer.server.port=80"

  penpot-backend:
    image: penpotapp/backend:latest
    container_name: penpot-backend
    restart: unless-stopped
    depends_on:
      penpot-postgres:
        condition: service_healthy
      penpot-redis:
        condition: service_started
    environment:
      - PENPOT_FLAGS=enable-registration enable-login-with-password
      - PENPOT_PUBLIC_URI=http://penpot.lab
      - PENPOT_DATABASE_URI=postgresql://penpot:${POSTGRES_PASSWORD}@penpot-postgres/penpot
      - PENPOT_REDIS_URI=redis://penpot-redis/0
      - PENPOT_ASSETS_STORAGE_BACKEND=assets-fs
      - PENPOT_STORAGE_ASSETS_FS_DIRECTORY=/opt/data/assets
    volumes:
      - penpot_assets:/opt/data/assets
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:6060/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - internal

  penpost-postgres:
    image: postgres:16-alpine
    container_name: penpot-postgres
    restart: unless-stopped
    environment:
      - POSTGRES_DB=penpot
      - POSTGRES_USER=penpot
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - penpot_db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U penpot"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - internal

  penpot-redis:
    image: redis:7-alpine
    container_name: penpot-redis
    restart: unless-stopped
    networks:
      - internal

networks:
  proxy:
    external: true
  internal:
    driver: bridge

volumes:
  penpot_assets:
  penpot_db:
```

### Environment (.env.example)

```bash
POSTGRES_PASSWORD=changeme
```

### DNS / routing

| Domain | Service | Network | Notes |
|--------|---------|---------|-------|
| `penpot.lab` | Traefik → penpot-frontend:80 | `proxy` | Web UI |
| Internal | penpot-backend:6060 | `internal` | Backend API (healthcheck) |

### Steps

1. Create `stacks/penpot/` with compose.yaml + .env.example
2. Add `penpot.lab` to Pi-hole DNS (`scripts/dns/dns-config.yaml`)
3. `docker compose up -d`
4. Create first admin user via browser at `http://penpot.lab`
5. Test SVG import (drag SVG file into Penpot canvas)
6. Test collaboration (share link + edit)

### Verification

```bash
# Backend health
curl -s http://penpot.lab/api/health

# UI access via browser
open http://penpot.lab

# Traefik route check
curl -sI -H "Host: penpot.lab" http://traefik:80/
```

### Integration with Hermes

Hermes can generate SVG code and serve it via `static.lab`. A workflow:

1. Hermes generates SVG wireframe → saves to `stacks/static/html/`
2. You open `static.lab/design.svg` → copy to Penpot
3. Or: Heremes writes a Python script that calls Penpot's REST API (Penpot has one, less mature than Figma's)

---

## Alternative: Figma API scripts (no container)

If you just want Hermes to manipulate Figma files programmatically:

1. Generate a Figma Personal Access Token (Settings → Account → Personal Access Tokens)
2. Write a Python script that uses `figma-export` or raw REST
3. Store token in secrets/ repo

Limitations:
- Can create frames, set text content, apply basic fills
- Cannot create components, variants, auto layout, prototypes
- Good for batch text updates and frame generation

---

## Decision

| Priority | Option | Complexity | Value | Decision |
|----------|--------|:----------:|:-----:|:--------:|
| 1 | **Penpot stack** | Low | High | ✅ Do this |
| 2 | Figma API scripts | Low | Medium | 🟡 Nice-to-have |
| 3 | Kasm Figma | High | Low | ❌ Overkill |
| 4 | Figma web | None | High | ✅ Already works |

**Penpot is the primary deliverable.** Low complexity, Docker-native, self-hosted, web UI. Hermes generates SVG/HTML specs that feed into it.

---

## Files to create

| File | Content |
|------|---------|
| `stacks/penpot/compose.yaml` | Docker Compose (4 services) |
| `stacks/penpot/.env.example` | Env vars |
| `scripts/dns/dns-config.yaml` | Add `penpot.lab` record |
| `docs/current-state.md` | Update stacks tree |

## Risks and open questions

- **Penpot Figma import** is experimental — may not handle complex .fig files
- **No official Hermes-Penpot integration** — would need custom scripts
- **Postgres volume** — needs backup strategy (same as other DB volumes)
- **Registration** — Penpot allows open registration by default. Safer to disable after admin user is created (`PENPOT_FLAGS=disable-registration` in reverse)
