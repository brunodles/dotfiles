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
import threading
import urllib.parse

DATA = os.environ.get("SYNC_DATA_DIR", "/data")
GITEA_URL = os.environ.get("GITEA_URL", "http://gitea:3000")
REPO = os.environ.get("GITEA_REPO", "hermes/docs")
TOKEN = os.environ.get("GITEA_TOKEN", "")
SECRET = os.environ.get("WEBHOOK_SECRET", "")
BRANCH = os.environ.get("SYNC_BRANCH", "main")
HOST = os.environ.get("SYNC_HOST", "0.0.0.0")
PORT = int(os.environ.get("SYNC_PORT", "8080"))

logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
log = logging.getLogger("docs-sync")

# ── Git helpers ────────────────────────────────────────────────────

_lock = threading.Lock()

def _configure_git():
    """One-time git config at module load."""
    subprocess.run(
        ["git", "config", "--global", "--add", "safe.directory", DATA],
        capture_output=True, timeout=5,
    )

_configure_git()


def _repo_url() -> str:
    """Build clone URL with optional token auth, preserving scheme."""
    scheme = "https" if GITEA_URL.startswith("https://") else "http"
    netloc = GITEA_URL.removeprefix("http://").removeprefix("https://")
    if TOKEN:
        return f"{scheme}://{TOKEN}@{netloc}/{REPO}.git"
    return f"{scheme}://{netloc}/{REPO}.git"


def _sanitize(text: str) -> str:
    """Remove tokens from error text to avoid credential leaks."""
    if not TOKEN:
        return text
    return text.replace(TOKEN, "***")


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
    if not _lock.acquire(blocking=False):
        return {"status": "skipped", "reason": "sync already in progress"}

    try:
        if os.path.isdir(f"{DATA}/.git"):
            out = subprocess.run(
                ["git", "-C", DATA, "pull", "origin", BRANCH],
                capture_output=True, text=True, check=True, timeout=30,
            )
            log.info("pull: %s", out.stdout.strip())
            hash_ = _last_commit_hash()
            return {"status": "ok", "action": "pull", "hash": hash_}
        else:
            os.makedirs(DATA, exist_ok=True)
            out = subprocess.run(
                ["git", "clone", "--branch", BRANCH, _repo_url(), DATA],
                capture_output=True, text=True, check=True, timeout=60,
            )
            log.info("clone: %s", out.stdout.strip())
            hash_ = _last_commit_hash()
            return {"status": "ok", "action": "clone", "hash": hash_}
    except subprocess.TimeoutExpired:
        log.error("git operation timed out")
        return {"status": "error", "reason": "timeout"}
    except subprocess.CalledProcessError as exc:
        msg = exc.stderr.strip() if exc.stderr else str(exc)
        log.error("git error: %s", _sanitize(msg))
        return {"status": "error", "reason": _sanitize(msg)}
    except Exception as exc:
        log.error("unexpected error: %s", exc)
        return {"status": "error", "reason": str(exc)}
    finally:
        _lock.release()


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
