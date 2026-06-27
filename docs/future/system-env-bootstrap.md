# System-wide Dockge Environment Bootstrap

**Goal:** Make `$DOCKGE_DATA_DIR`, `$DOCKGE_STACKS_DIR`, and friends available system-wide so `docker compose up` works directly from any stack directory without sourcing `_env.source.sh` first.

**Architecture:** A reusable script `scripts/bootstrap/env` that writes Dockge env vars to `/etc/environment`. Each host's `configure.sh` calls it. Idempotent — safe to re-run.

---

## Tasks

### Task 1: Create `scripts/bootstrap/env`

**File:** `scripts/bootstrap/env` (create)

```bash
#!/usr/bin/env bash
# env — Install Dockge environment variables system-wide into /etc/environment
# Makes DOCKGE_DIR, DOCKGE_DATA_DIR, etc. available to all users and processes.
set -euo pipefail

BOOTSTRAP_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BOOTSTRAP_DIR/_log.source.sh"

ENV_FILE="/etc/environment"

read -r -d '' NEW_BLOCK <<'DOCKGE_BLOCK' || true
# Dockge paths (managed by dotfiles)
DOCKGE_DIR=/dockge
DOCKGE_DOCKGE_DIR=/dockge/dockge
DOCKGE_STACKS_DIR=/dockge/stacks
DOCKGE_DATA_DIR=/dockge/data
DOCKGE_BLOCK

# Normalize trailing newlines for comparison
normalize() { grep '^DOCKGE_' "$1" 2>/dev/null | sort || true; }

apply_env() {
  local tmp
  tmp=$(mktemp)
  # shellcheck disable=SC2064
  trap "rm -f '$tmp'" RETURN

  if [[ -f "$ENV_FILE" ]] && grep -qF '# Dockge paths' "$ENV_FILE"; then
    # Strip existing Dockge block, append new one
    awk '
      /^# Dockge paths/ { skip = 1; next }
      skip && /^[^#]/ { skip = 0 }
      skip { next }
      { print }
    ' "$ENV_FILE" > "$tmp"
    printf "\n%s\n" "$NEW_BLOCK" >> "$tmp"
  else
    # Append to file (ensure leading newline if non-empty)
    if [[ -f "$ENV_FILE" ]] && [[ -s "$ENV_FILE" ]] && [[ "$(tail -c1 "$ENV_FILE" | wc -l)" -eq 0 ]]; then
      printf "\n" > "$tmp"
      cat "$ENV_FILE" >> "$tmp"
    else
      cp "$ENV_FILE" "$tmp" 2>/dev/null || true
    fi
    printf "\n%s\n" "$NEW_BLOCK" >> "$tmp"
  fi

  sudo cp "$tmp" "$ENV_FILE"
  sudo chmod 644 "$ENV_FILE"
}

# Check current state
if [[ -f "$ENV_FILE" ]] && grep -qF '# Dockge paths' "$ENV_FILE"; then
  CURRENT=$(normalize "$ENV_FILE")
  EXPECTED=$(grep '^DOCKGE_' <<< "$NEW_BLOCK" | sort)
  if [[ "$CURRENT" == "$EXPECTED" ]]; then
    info "Dockge env vars already up to date in $ENV_FILE"
    exit 0
  fi
  info "Updating Dockge env vars in $ENV_FILE..."
else
  info "Installing Dockge env vars into $ENV_FILE..."
fi

apply_env
info "Done — Dockge environment variables installed to $ENV_FILE"
info "Log out and back in (or run 'source /etc/environment') for changes to take effect."
```

Make executable: `chmod +x scripts/bootstrap/env`

---

### Task 2: Update VPS `configure.sh` to call `scripts/bootstrap/env`

**File:** `hosts/vps/bootstrap/configure.sh` (modify)

Add after `source` lines, before the stack symlink section:

```bash
source "$BOOTSTRAP_DIR/_env.source.sh"
source "$BOOTSTRAP_DIR/_log.source.sh"
```

Wait — this file already sources `_env.source.sh` and `_log.source.sh`. The change is to add the env script call after the sources:

```bash
# Ensure system-wide env vars
"$SCRIPT_BOOTSTRAP_DIR/env"
```

Right after the `source` lines and `REPO_ROOT` assignment, before the `info "Setting up /dockge/ stack symlinks..."` line.

---

### Task 3: Update Media `configure.sh` to call `scripts/bootstrap/env`

**File:** `hosts/media/bootstrap/configure.sh` (modify)

Currently:
```bash
#!/usr/bin/env bash
BOOTSTRAP_DIR="$HOME/dotfiles/scripts/bootstrap/"
$BOOTSTRAP_DIR/dockge traefik gitea jellyfin metube syncthing
$BOOTSTRAP_DIR/traefik
```

Add the env call before dockge/traefik:
```bash
#!/usr/bin/env bash
# configure.sh — Configure media server: env, stacks, Docker network
BOOTSTRAP_DIR="$HOME/dotfiles/scripts/bootstrap/"

$BOOTSTRAP_DIR/env
$BOOTSTRAP_DIR/dockge traefik gitea jellyfin metube syncthing
$BOOTSTRAP_DIR/traefik
```

---

### Task 4: VPS `configure.sh` — Detailed change

Current file:
```bash
#!/usr/bin/env bash
# configure.sh — Configure VPS: stack symlinks, Docker network, workspace
source "$HOME/dotfiles/scripts/bootstrap/_log.source.sh"
source "$HOME/dotfiles/scripts/bootstrap/_env.source.sh"

REPO_ROOT="$(cd "$HOST_DIR/../.." && pwd)"
STACKS_SRC="$REPO_ROOT/stacks"

info "Setting up /dockge/ stack symlinks..."
```

Change to:
```bash
#!/usr/bin/env bash
# configure.sh — Configure VPS: env, stack symlinks, Docker network, workspace
source "$HOME/dotfiles/scripts/bootstrap/_log.source.sh"
source "$HOME/dotfiles/scripts/bootstrap/_env.source.sh"

REPO_ROOT="$(cd "$HOST_DIR/../.." && pwd)"
STACKS_SRC="$REPO_ROOT/stacks"

# Ensure system-wide env vars for docker compose
"$SCRIPT_BOOTSTRAP_DIR/env"

info "Setting up /dockge/ stack symlinks..."
```

---

## Verification

### Per host after bootstrap

1. **Check `/etc/environment` content:**
   ```bash
   grep 'DOCKGE_' /etc/environment
   ```
   Expected:
   ```
   DOCKGE_DIR=/dockge
   DOCKGE_DOCKGE_DIR=/dockge/dockge
   DOCKGE_STACKS_DIR=/dockge/stacks
   DOCKGE_DATA_DIR=/dockge/data
   ```

2. **Test compose resolution:**
   ```bash
   source /etc/environment
   cd /dockge/stacks/hermes
   docker compose config 2>&1 | grep DOCKGE_DATA_DIR
   ```
   Should show no errors — `$DOCKGE_DATA_DIR` resolves to `/dockge/data`.

3. **Idempotency test:**
   Run `scripts/bootstrap/env` again — should print "already up to date" and make no changes.

---

## Risks & Notes

- **`/etc/environment` uses `key=value` format** — no `export`, no quotes, no variable expansion. All Dockge vars are absolute paths, so this is safe.
- **`/etc/environment` is read by PAM** on login (both login and non-login shells). `systemctl --user` services also inherit it. Covers all our use cases.
- **Requires `sudo`** to write — already the pattern in `_env.source.sh` and configure scripts.
- **Existing sessions won't see the new vars** until next login. Added info log to warn about this.
- **Arch Linux**: PAM may need `pam_env` in the auth stack. Ubuntu (our VPS/media/silver) includes it by default. Docker's PAM stack varies — `docker compose` reads shell env, not PAM env, so this is fine.
