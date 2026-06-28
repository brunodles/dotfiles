#!/usr/bin/env python3
"""docs-sync — HTTP server for git-based docstore sync.

Receives Gitea webhooks and exposes health/status endpoints.
Git operations are serialised via a non-blocking lock so concurrent
webhooks (or webhook + poll) never race on the same repository.
"""

import http.server
import json
import logging
import os
import subprocess
import sys

DATA = os.environ.get("SYNC_DATA_DIR", "/data")
GITEA_URL = os.environ.get("GITEA_URL", "http://gitea:3000")
REPO = os.environ.get("GITEA_REPO", "hermes/docs")
SECRET = os.environ.get("WEBHOOK_SECRET", "")
HOST = os.environ.get("SYNC_HOST", "0.0.0.0")
PORT = int(os.environ.get("SYNC_PORT", "8080"))

logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
log = logging.getLogger("docs-sync")

# ── Git helpers ────────────────────────────────────────────────────

_repo_locked = False


def _repo_url() -> str:
    token = os.environ.get("GITEA_TOKEN", "")
    netloc = GITEA_URL.removeprefix("http://").removeprefix("https://")
    if token:
        return f"http://{token}@{netloc}/{REPO}.git"
    return f"http://{netloc}/{REPO}.git"


def _last_commit_hash() -> str:
    try:
        out = subprocess.run(
            ["git", "-C", DATA, "rev-parse", "--short", "HEAD"],
            capture_output=True, text=True, check=True, timeout=15,
        )
        return out.stdout.strip()
    except Exception:
        return "none"


def sync() -> dict:
    """Pull (or clone) the docs repository. Returns status dict."""
    global _repo_locked
    if _repo_locked:
        return {"status": "skipped", "reason": "sync already in progress"}

    _repo_locked = True
    try:
        if os.path.isdir(f"{DATA}/.git"):
            out = subprocess.run(
                ["git", "-C", DATA, "pull"],
                capture_output=True, text=True, check=True, timeout=30,
            )
            log.info("pull: %s", out.stdout.strip())
            hash_ = _last_commit_hash()
            return {"status": "ok", "action": "pull", "hash": hash_}
        else:
            os.makedirs(DATA, exist_ok=True)
            out = subprocess.run(
                ["git", "clone", _repo_url(), DATA],
                capture_output=True, text=True, check=True, timeout=60,
            )
            log.info("clone: %s", out.stdout.strip())
            hash_ = _last_commit_hash()
            return {"status": "ok", "action": "clone", "hash": hash_}
    except subprocess.TimeoutExpired:
        log.error("git operation timed out")
        return {"status": "error", "reason": "timeout"}
    except subprocess.CalledProcessError as exc:
        log.error("git error: %s", exc.stderr.strip() if exc.stderr else str(exc))
        return {"status": "error", "reason": exc.stderr.strip() if exc.stderr else str(exc)}
    except Exception as exc:
        log.error("unexpected error: %s", exc)
        return {"status": "error", "reason": str(exc)}
    finally:
        _repo_locked = False


# ── HTTP handlers ──────────────────────────────────────────────────

class Handler(http.server.BaseHTTPRequestHandler):
    """Minimal HTTP handler for webhook + health."""

    def _respond(self, code: int, body: dict):
        payload = json.dumps(body).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_POST(self):
        if self.path.startswith("/hook"):
            secret = self._query_param("secret") or ""
            if SECRET and secret != SECRET:
                log.warning("webhook rejected: invalid secret")
                return self._respond(403, {"status": "error", "reason": "invalid secret"})
            result = sync()
            self._respond(200, result)
        else:
            self._respond(404, {"status": "error", "reason": "not found"})

    def do_GET(self):
        if self.path in ("/health", "/status"):
            self._respond(200, {
                "status": "ok",
                "repo": f"{GITEA_URL}/{REPO}",
                "hash": _last_commit_hash(),
            })
        else:
            self._respond(404, {"status": "error", "reason": "not found"})

    def _query_param(self, name: str) -> str | None:
        import urllib.parse
        if "?" not in self.path:
            return None
        qs = self.path.split("?", 1)[1]
        params = urllib.parse.parse_qs(qs)
        values = params.get(name, [])
        return values[0] if values else None

    def log_message(self, format, *args):
        log.info("http: %s", format % args)


# ── Main ───────────────────────────────────────────────────────────

def main():
    if not SECRET:
        log.warning("WEBHOOK_SECRET is empty — webhook endpoint is unprotected")

    # Run initial sync on startup
    result = sync()
    log.info("initial sync: %s", json.dumps(result))

    server = http.server.HTTPServer((HOST, PORT), Handler)
    log.info("listening on %s:%d", HOST, PORT)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        log.info("shutting down")
        server.shutdown()


if __name__ == "__main__":
    main()
