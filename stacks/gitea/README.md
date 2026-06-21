# Gitea

Self-hosted Git service for the VPS. Hermes uses it as its local
git server — pushes commits, creates issues, and files tickets
without depending on GitHub.

## Access

| Method | URL | Notes |
|--------|-----|-------|
| Tailscale | `http://100.x.x.x:3000` | From any tailnet device |
| Hermes | `http://gitea:3000` | Docker internal, no auth |
| Local | `http://localhost:3000` | From the VPS host |

Port 3000 is exposed but **blocked on the public firewall** —
only accessible via Tailscale or internally.

## First-time setup

### 1. Set the database password

```bash
cp .env.example .env
# Edit .env and set GITEA_DB_PASSWORD
```

### 2. Start the stack

```bash
docker compose up -d
```

### 3. Create the admin user

```bash
docker compose exec gitea gitea admin user create \
  --username <admin> \
  --password <pass> \
  --email <your@email.com> \
  --admin
```

### 4. Create the Hermes user

```bash
docker compose exec gitea gitea admin user create \
  --username hermes \
  --password <token-or-pass> \
  --email hermes@vps
```

### 5. Configure Hermes to use Gitea

On the host (where Hermes runs), add the Gitea remote:

```bash
cd /opt/data
git remote add gitea http://gitea:3000/hermes/dotfiles.git
git push gitea main
```

Or clone from Gitea for future work:

```bash
git clone http://gitea:3000/hermes/dotfiles.git
```

## Configuration

The compose sets:

| Setting | Value | Why |
|---------|-------|-----|
| `INSTALL_LOCK` | `true` | Skip web installer on first visit |
| `DISABLE_REGISTRATION` | `true` | Only admin-created users |
| `DISABLE_SSH` / `START_SSH_SERVER` | `true` / `false` | HTTP-only access, simpler |
| Database | Postgres 16 | Reliable, well-supported |

## Backups

Gitea data lives in named volumes:

- `gitea-data` — repos, config, sessions
- `gitea-db-data` — Postgres database

To back up:

```bash
docker compose exec gitea-db pg_dump -U gitea gitea > backup.sql
```

Or snapshot the volumes.
