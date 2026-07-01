# Improvement: Review — docs-sync service

**Source:** Subagent review `deleg_a63832b2`  
**Date:** 2026-06-28

## Issues found (ordered by severity)

### 1. [CRITICAL] Hardcoded `http://` scheme in clone URL

`_repo_url()` hardcodes `http://` instead of deriving scheme from `GITEA_URL`.

```python
return f"http://{token}@{netloc}/{REPO}.git"
```

If Gitea is served over HTTPS, this downgrades to HTTP and leaks credentials.

**Fix:** Derive scheme from `GITEA_URL`; keep `://` prefix stripping for netloc.

### 2. [HIGH] Missing `git config safe.directory`

Newer git refuses to operate on repos owned by a different UID. The Docker
volume `docs_data` has a different owner than the container's `python` user.

**Fix:** Add `RUN git config --global --add safe.directory /data` to Dockerfile
OR call it at startup in `sync.py`.

### 3. [HIGH] Token leaked in git error responses

Git stderr includes the full remote URL (with embedded token) on failure.
The `sync()` function returns this unfiltered to the webhook caller.

**Fix:** Strip the token from error messages before returning.

### 4. [MEDIUM] Boolean lock is racy (latent bug)

`_repo_locked` boolean is safe with single-threaded `HTTPServer` but would
race with `ThreadingHTTPServer` or any async server.

**Fix:** Use `threading.Lock()` with `acquire(blocking=False)`.

### 5. [LOW] Env var naming inconsistency

`DOCS_WEBHOOK_SECRET` in `.env.example` and compose → `WEBHOOK_SECRET`
inside the container → `WEBHOOK_SECRET` in sync.py. The cron container
uses `DOCS_WEBHOOK_SECRET`. One name should flow through.

**Fix:** Use `WEBHOOK_SECRET` everywhere. Keep `DOCS_` prefix in `.env` only.

### 6. [LOW] `.env.example` has empty values for required vars

`GITEA_TOKEN=` and `DOCS_WEBHOOK_SECRET=` are empty. If someone copies
`.env.example` → `.env` without filling them, compose fails silently.

**Fix:** Use placeholder values (`changeme`, `generate-via-openssl`).

### 7. [LOW] `git pull` doesn't specify branch

`git pull` relies on default remote tracking. Could pull unexpected branches.

**Fix:** Use `git pull origin main`.

### 8. [LOW] Unused `import sys`

```python
import sys  # never used
```

**Fix:** Remove unused import.
