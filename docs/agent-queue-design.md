# Agent Queue Design — Multi-Agent Git Coordination

## Problem

Multiple AI agents (Hermes Agent, Claude Code, Copilot CLI) operate on the same
Git repository concurrently from isolated sessions. Without coordination, this
creates:

- **Simultaneous writes** to the same file from two agents
- **Race conditions** — Agent B's commit is based on stale state before Agent A's
  commit lands
- **Lost commits** — `git push --force` or rebase conflicts
- **Diverged branches** with no human to reconcile
- **Dependency violations** — a rename happens before the file that references it

The canonical scenario: restructuring a dotfiles repo across 6 hosts
(e.g. migrating `host/*` → `hosts/*`), where each host is a separate commit,
and the commits must be sequential AND ordered so that global reference updates
come last.

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────┐
│                    GIT REPOSITORY (.git/)                     │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐             │
│  │  main      │  │  queue/    │  │  agents/   │             │
│  │  (protected)│  │  (metadata)│  │  (config)  │             │
│  └────────────┘  └────────────┘  └────────────┘             │
└──────────────────────┬───────────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ Hermes Agent │ │ Claude Code  │ │ Copilot CLI  │
│  (VPS)       │ │  (work)      │ │  (silver)    │
└──────────────┘ └──────────────┘ └──────────────┘
        │              │              │
        └──────────────┴──────────────┘
                       │
                       ▼
          ┌──────────────────────┐
          │   Queue Directory    │
          │   repo/.git-queue/   │
          │                      │
          │  ┌────┐ ┌────┐ ┌───┐│
          │  │lock│ │task│ │log││
          │  └────┘ └────┘ └───┘│
          └──────────────────────┘
```

Each agent runs a `git-queue` wrapper script before every Git operation.
The wrapper:
1. Acquires a lock (or waits)
2. Reads the task queue
3. Validates dependencies
4. Performs the Git operation
5. Releases the lock
6. Advances the queue

---

## Three Approaches Compared

### Approach A: File-Based Lock + JSON Task Queue (Recommended)

A `.git-queue/` directory at repo root stores lock files and task manifests.
No external services. No special Git setup.

**Locking**:
- `flock()` on a single `repo.lock` file for mutual exclusion
- Fast-path: read-only operations skip the lock
- Write operations acquire a POSIX `flock` via `exec 200>repo.lock; flock -n 200`

**Queue**:
- Tasks are JSON files: `.git-queue/tasks/<id>.json`
- Each task has: owner, files[], depends_on[], status, timeout
- Status transitions: pending → acquired → running → complete | failed

**Pros:**
- Zero dependencies — only POSIX tools and Git
- Works offline, no network or Redis required
- Transparent — can be inspected with `cat .git-queue/tasks/*.json`
- Easy to recover — delete stale lock, re-queue failed task
- Integrates naturally with Hermes cron (scripts in repo)
- Git hooks can check queue state before allowing pushes

**Cons:**
- Not distributed — all agents must share a filesystem (e.g., NFS, or
  use the Git repo itself as transport — see Approach B)
- No built-in priority queue (can be added via priority field + sort)
- Single lock file is a bottleneck under high contention
- Stale lock files require TTL/heartbeat or manual cleanup

---

### Approach B: Git Branch Per Agent + Merge Tracking

Each agent gets a dedicated branch (`agent/hermes/main`,
`agent/claude/main`, `agent/copilot/main`) and works independently.
A coordinator process (or human) merges branches.

**Locking**: No lock needed — Git branches provide isolation.
**Queue**: The queue is implicit: a shared `QUEUE.md` or TOML manifest
in the repo tracks what each branch is supposed to do.

**Pros:**
- Full isolation — no agent can break another in-flight
- Git-native — no lock files, no `flock`
- Merge conflicts are surfaced by Git's normal merge machinery
- Reviewable — each branch can be reviewed before merge
- Works across hosts without shared filesystem (just `git push`)

**Cons:**
- Requires a merge coordinator (human + CI, or a designated "merger agent")
- Dependency tracking requires external metadata (which branch needs
  which other branch to land first)
- Merge conflicts happen at the END instead of being prevented early
- Higher cognitive overhead — each agent must push/pull branches
- Complex recovery if the coordinator crashes mid-merge
- Branch explosion: N agents × M tasks = N × M branches

---

### Approach C: External Redis Queue

A lightweight Redis instance (or SQLite) acts as the coordination backbone.
Agents connect to it to dequeue tasks, acquire locks, and report status.

**Pros:**
- Atomic operations (`SETNX`, `BRPOPLPUSH`) for robust locking
- Built-in TTL for lock expiry
- Real-time visibility — `redis-cli monitor` shows every operation
- Priority queues via `ZADD` / `ZPOPMIN`
- Distributed by design — agents on different hosts can coordinate

**Cons:**
- External dependency — must run Redis somewhere (or SQLite on shared FS)
- Network latency + connectivity issues
- Another thing to back up and monitor
- Overkill for 3–6 agents on a single repo
- Adds operational complexity to a homelab

---

## Recommended Approach: Approach A (File-Based)

For the dotfiles repo scenario (homelab, 3–6 agents, single repo),
**Approach A — file-based lock + JSON task queue** is the right balance.

Why:
- The repo is ~5 MB, low churn rate (dozens of commits per week, not thousands)
- Agents primarily operate on different hosts — contention on the same file
  is the exception, not the rule
- No external infrastructure required
- Transparent and debuggable with basic shell tools
- The queue can live IN the repo itself (committed `.git-queue/`), making
  it visible to all agents when they pull before work

---

## Detailed Design

### 1. Directory Structure

```
.git-queue/
├── lock                   # POSIX flock mutual exclusion
├── task-manifest.json     # Summary of all tasks
├── tasks/
│   ├── 001.json           # Task definition
│   ├── 002.json
│   └── ...
├── tokens/                # Agent heartbeat tokens
│   ├── hermes.heartbeat
│   ├── claude.heartbeat
│   └── copilot.heartbeat
├── completed/             # Archived completed tasks
└── agent-log/             # Per-agent journal
    ├── hermes.log
    ├── claude.log
    └── copilot.log
```

### 2. Task JSON Schema

```json
{
  "id": "TASK-003",
  "title": "Migrate host/pi → hosts/pi with split bootstrap",
  "owner": "hermes",
  "status": "pending",
  "files": [
    "host/pi/bootstrap.sh",
    "hosts/pi/bootstrap.sh",
    "hosts/pi/bootstrap/install.sh",
    "hosts/pi/bootstrap/configure.sh",
    "hosts/pi/bootstrap/links.sh",
    "hosts/pi/bootstrap/lib.sh"
  ],
  "depends_on": ["TASK-001", "TASK-002"],
  "blocks": ["TASK-007"],
  "branch": "refactor/pi-migration",
  "timeout_seconds": 600,
  "created_at": "2026-06-21T12:00:00Z",
  "started_at": null,
  "completed_at": null,
  "retry_count": 0,
  "max_retries": 3
}
```

### 3. Lock Protocol

All write operations follow this sequence:

```
1. Pull latest .git-queue/ from origin
2. Acquire lock: exec 200>.git-queue/lock; flock -n 200 || exit 75
3. Validate: no other agent holds a stale lock (check heartbeat tokens)
4. Dequeue: find {status:pending, all-dependencies-satisfied} task
5. Claim: set status=acquired, owner=$AGENT_ID
6. Record heartbeat every 30s while working
7. Execute changes (edit files, commit, push)
8. Mark: set status=complete, push .git-queue/ + work
9. Release lock (exit releases flock naturally)
```

**Lock contention handling:**
- If `flock -n` fails (lock held), wait with exponential backoff:
  1s → 2s → 4s → 8s → max 60s, then fail with message
- Agent should queue itself as waiting in `waiting_agents` field

**Heartbeat mechanism:**
- While holding the lock, agent writes timestamp to
  `.git-queue/tokens/<agent>.heartbeat` every 30 seconds
- On acquire, lock holder checks all heartbeat tokens:
  - If token is > 10 minutes old, assume stale and release it
  - Log warning with agent name and stale duration

### 4. Dequeue Logic

```
dequeue():
    tasks = load_all_tasks()
    # Filter: status == pending
    pending = [t for t in tasks if t.status == "pending"]
    # Filter: all dependencies satisfied
    ready = [
        t for t in pending
        if all(tasks[d].status == "complete" for d in t.depends_on)
    ]
    # Sort by: priority (highest first), then created_at (oldest first)
    ready.sort(key=lambda t: (-t.priority, t.created_at))
    if ready: return ready[0]
    # If nothing ready, report what's blocking
    blocked = [t for t in pending if not ready]
```

### 5. Dependency Graph

Tasks form a DAG. The dependency graph must be acyclic — enforced on
task creation.

Example for the 6-host migration scenario:

```
TASK-001 (android) ──┐
TASK-002 (media)   ──┤
TASK-003 (pi)      ──┤
TASK-004 (silver)  ──┼──▶ TASK-007 (update global refs)
TASK-005 (vps)     ──┤
TASK-006 (work)    ──┘
```

Each host migration is independent (parallel). The global reference update
(`host/` → `hosts/` in scripts, docs, configs) waits for all six to complete.

### 6. Conflict Resolution

**Same-file contention detection:**
When dequeuing a task, check that the task's `files[]` do not overlap with
files in any `acquired` or `running` task. If overlap is detected:

1. Log: "Conflict detected: file X is claimed by TASK-Y (status=running)"
2. Move task back to pending with a `conflict_with` annotation
3. The conflicting task's `blocks` field should list this task
4. Notify via agent logs

**Granularity:**
- File-level locking in the task manifest
- Multiple files per task is allowed
- Two tasks cannot claim overlapping file sets unless one marks the file
  as `shared: true` (read-only reference updates)

**Merge conflicts at commit time:**
If despite locks two agents produce overlapping commits, Git's normal
merge machinery applies. The queue wrapper detects a failed push
(rejected by remote) and:

1. Stashes current work
2. Pulls latest
3. Re-queues the task with `retry_count + 1`
4. If retry_count > max_retries, marks as `failed` and alerts

### 7. Recovery Scenarios

| Failure | Detection | Recovery |
|---------|-----------|----------|
| Agent crashes while holding lock | Heartbeat stops updating; next agent finds stale token | Cleanup: release lock, mark acquired→failed tasks as pending with `retry_count+1` |
| Queue script crashes mid-commit | Lock released (flock released on process exit); incomplete commit detected via `rebase --abort` equivalent | Next agent rolls back any partial state |
| Stale lock file (filesystem leftover) | `flock -n` always fails; expected holder has no heartbeat | Delete lock file (safe because flock releases on descriptor close) |
| Task times out (agent stuck for >timeout_seconds) | Current time > started_at + timeout_seconds | Set status=timeout; next agent may re-acquire and continue; manual review recommended |
| Conflicting edits merge fails | `git merge` or `git push` returns non-zero | Rollback, re-pull, increment retry, re-attempt; after max_retries, flag for human |
| Agent pushes without going through queue | Git hook rejects push (see Section 8) | Push must be re-done via queue wrapper |
| .git-queue/ itself has merge conflict | Two agents added tasks simultaneously | Resolve by accepting both tasks; deduplicate by task ID |

### 8. Integration Points

**Git Hooks (`hooks/pre-push`):**

```bash
#!/bin/bash
# pre-push — verify push follows queue protocol
set -euo pipefail

AGENT_ID="${GIT_QUEUE_AGENT:-unknown}"
TASK_ID="${GIT_QUEUE_TASK:-none}"

if [ "$AGENT_ID" = "unknown" ] || [ "$TASK_ID" = "none" ]; then
    echo "❌ Push rejected: not executed via git-queue wrapper."
    echo "   Set GIT_QUEUE_AGENT and GIT_QUEUE_TASK environment variables,"
    echo "   or use the queue wrapper script."
    exit 1
fi

# Verify task is actually claimed by this agent
TASK_FILE=".git-queue/tasks/${TASK_ID}.json"
if [ ! -f "$TASK_FILE" ]; then
    echo "❌ Push rejected: task $TASK_ID not found in queue."
    exit 1
fi

# Verify only allowed files are pushed
task_files=$(jq -r '.files[]' "$TASK_FILE" | tr '\n' ' ')
echo "✅ Queue check passed: $AGENT_ID / $TASK_ID"
exit 0
```

**CI/CD Integration (GitHub Actions / Gitea Actions):**

```yaml
# .gitea/workflows/queue-check.yml
name: Queue Compliance
on: [push]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Verify queue compliance
        run: |
          if [ -z "${GIT_QUEUE_TASK:-}" ]; then
            echo "Warning: push without queue context"
          else
            echo "Task: $GIT_QUEUE_TASK"
            jq . ".git-queue/tasks/$GIT_QUEUE_TASK.json"
          fi
```

**Hermes Agent Cron Integration:**

A `.git-queue/cron/` directory can hold scheduled tasks. Hermes Agent's
cron system checks this directory and enqueues tasks automatically:

```yaml
# .git-queue/cron/daily-maintenance.yaml
schedule: "0 3 * * *"
task:
  title: "Daily repo maintenance"
  owner: "hermes"
  files: []
  depends_on: []
  actions:
    - git gc --aggressive
    - git prune
```

**Agent Instructions (CLAUDE.md / instructions.md):**

Each agent's instruction file should include:

> ### Git Queue Protocol
>
> Before making any change to this repository:
> 1. Run `scripts/git-queue acquire` to get a task lock
> 2. Check `.git-queue/tasks/` for pending tasks
> 3. Complete your work, commit, and push
> 4. Run `scripts/git-queue release` to mark the task complete
>
> Never push directly to main without going through the queue.
> Never hold the lock longer than 10 minutes without a heartbeat.

---

## Implementation: `scripts/git-queue` Wrapper

### Core Commands

```
Usage: git-queue <command> [options]

Commands:
  init                  Initialize .git-queue/ directory
  status                Show queue state (pending, running, completed, failed)
  add <task.json>       Add a task to the queue (validates DAG acyclicity)
  acquire               Acquire lock and dequeue next ready task
  release               Mark current task as complete and release lock
  heartbeat             Update heartbeat timestamp (called internally)
  fail [reason]         Mark current task as failed
  retry <task-id>       Re-queue a failed task
  cleanup               Remove stale locks and expired heartbeats
  show <task-id>        Show task details
  graph                 Print dependency graph (DOT format for Graphviz)
```

### Example Session

```bash
# Agent 1 (Hermes) — enqueue tasks
$ git-queue add tasks/android-migration.json
$ git-queue add tasks/media-migration.json
# ...

# Agent 1 — work on android
$ export GIT_QUEUE_AGENT=hermes GIT_QUEUE_TASK=TASK-001
$ git-queue acquire
  ✅ Lock acquired
  🎯 Dequeued: TASK-001 — Migrate host/android → hosts/android
  Files: host/android/* → hosts/android/*

# ... make changes, commit locally ...

$ git push
  ✅ Queue check passed
$ git-queue release
  ✅ TASK-001 complete

# Agent 2 (Claude) — automatically gets media migration on next acquire
$ export GIT_QUEUE_AGENT=claude GIT_QUEUE_TASK=TASK-002
$ git-queue acquire
  ✅ Lock acquired
  🎯 Dequeued: TASK-002 — Migrate host/media → hosts/media
```

---

## Edge Cases and Failure Modes

### 1. Two agents acquire the same task

**Scenario**: Network partition causes Agent A and Agent B both think they
acquired TASK-003.

**Mitigation**: The task JSON includes `owner` and `started_at`. When the
second agent attempts to claim it, it sees status=acquired and skips it.
The stale agent's heartbeat will eventually timeout (10 min TTL), allowing
another agent to pick up the task for retry.

### 2. Deadlock — Task A depends on B, B depends on A

**Scenario**: A dependency cycle is accidentally created.

**Mitigation**: The `add` command validates the dependency graph is a DAG
(Topological sort must succeed). If adding an edge creates a cycle, the
command rejects it with an error message showing the cycle.

### 3. Long-running agent dies mid-task

**Scenario**: Agent holds lock, edits 3 files, then crashes (OOM, network drop).

**Mitigation**:
- POSIX `flock` is tied to the process — if the agent dies, the lock
  file descriptor closes automatically
- Next agent to acquire will find status=acquired, owner matches no
  live heartbeat → marks as failed, logs the event
- Failed task can be manually reviewed and retried

### 4. Recovery from a queue with stale entries

**Scenario**: Power outage during task creation; partial task files exist.

**Mitigation**:
- `git-queue status` reports any inconsistencies
- `git-queue cleanup` removes tasks with missing required fields
- A `journal` in `.git-queue/journal/` records every state transition
  with a timestamp, so recovery can replay actions

### 5. `.git-queue/` state gets out of sync with Git

**Scenario**: An agent bypasses the queue (direct `git push --force`).

**Mitigation**:
- Pre-push hook (see Section 8) rejects pushes without queue metadata
- If bypassed anyway, the queue state is stale — run `git-queue sync`
  which compares `.git-queue/completed/` against `git log` and marks
  any unaccounted commits

### 6. Two agents both modify the same file at the same directory level

**Scenario**: Agent A renames `host/android` → `hosts/android`. Agent B
wants to add `host/android/foo.conf`.

**Mitigation**:
- The task's `files[]` field acts as a lock set. If Agent B's task lists
  `host/android/foo.conf`, the dequeue logic checks that no acquired/running
  task claims `host/android/` prefix → conflict → Agent B is blocked until
  Agent A completes.
- This is file-level locking, not repo-level. Agent B could work on
  `hosts/media/` simultaneously.

### 7. Shared file updates (e.g., README, CHANGELOG)

**Scenario**: Two tasks both need to update `README.md`.

**Mitigation**:
- Mark the file with `"shared": true` in the task manifest
- Shared files skip the conflict check
- The agent must read-merge: pull latest before edit, append/insert rather
  than overwrite
- A post-merge step (`git add -p`) may be needed

---

## Summary: Approach Comparison

| Criteria | A: File-Based Lock | B: Branch Per Agent | C: External Redis |
|---|---|---|---|
| **Dependencies** | None (POSIX only) | None (Git only) | Redis server |
| **Setup complexity** | Low | Medium | Medium-high |
| **Conflict prevention** | File-level locks (prevention) | None (detection at merge) | Task-level locks |
| **Fault tolerance** | Good (flock auto-release) | Good (branches are durable) | Good (TTL expiry) |
| **Offline capability** | Yes | Yes | No |
| **Distributed (multi-host)** | Shared FS needed | Yes (git push/pull) | Yes (network) |
| **Overhead per operation** | Low (flock is fast) | Medium (branch ops) | Low (Redis is fast) |
| **Debuggability** | High (plain JSON files) | Medium (git log --graph) | Medium (redis-cli) |
| **Best for** | Single-host agents, homelab | Multi-host, CI-reconciled | High-throughput, distributed |

**Recommended: Approach A** for the dotfiles repo (homelab scale).
If agents are on different machines without shared filesystem, combine
with a lightweight Git-based queue transport: commit `.git-queue/tasks/*.json`
to the repo itself, and use `git push` / `git pull` as the transport layer.
That hybrid gives the best of both worlds — no external service, works
across hosts.

---

## Appendix: bash Implementation Sketch

```bash
#!/usr/bin/env bash
# scripts/git-queue — Queue-based Git coordination
set -euo pipefail

QUEUE_DIR="$(git rev-parse --show-toplevel)/.git-queue"
LOCK_FILE="$QUEUE_DIR/lock"
AGENT_ID="${GIT_QUEUE_AGENT:-unknown}"
TASK_ID="${GIT_QUEUE_TASK:-none}"

_ensure_queue() {
    mkdir -p "$QUEUE_DIR"/{tasks,tokens,completed,agent-log}
    [ -f "$LOCK_FILE" ] || touch "$LOCK_FILE"
}

_acquire_lock() {
    exec 200>"$LOCK_FILE"
    local waited=0
    until flock -n 200 2>/dev/null; do
        if [ "$waited" -ge 60 ]; then
            echo "❌ Could not acquire lock after 60s" >&2
            return 1
        fi
        sleep 2
        waited=$((waited + 2))
    done
    _check_stale_locks
    echo "✅ Lock acquired"
}

_release_lock() {
    # flock releases automatically when FD 200 closes
    exec 200>&-
    echo "🔓 Lock released"
}

_check_stale_locks() {
    for token in "$QUEUE_DIR/tokens"/*.heartbeat; do
        [ -f "$token" ] || continue
        local age=$(( $(date +%s) - $(stat -c %Y "$token") ))
        if [ "$age" -gt 600 ]; then
            local agent=$(basename "$token" .heartbeat)
            echo "⚠️  Stale lock detected: $agent (${age}s old)" >&2
            rm -f "$token"
        fi
    done
}

_heartbeat() {
    local token="$QUEUE_DIR/tokens/${AGENT_ID}.heartbeat"
    touch "$token"
}

case "${1:-help}" in
    init)
        _ensure_queue
        echo "✅ .git-queue initialized"
        ;;
    acquire)
        _ensure_queue
        _acquire_lock
        _heartbeat
        # TODO: dequeue and claim next ready task
        echo "Ready to work (TASK: $TASK_ID)"
        ;;
    release)
        # TODO: mark current task complete, push
        _release_lock
        echo "✅ Task complete"
        ;;
    heartbeat)
        _heartbeat
        ;;
    cleanup)
        _check_stale_locks
        rm -f "$QUEUE_DIR/lock"
        echo "✅ Cleanup complete"
        ;;
    *)
        echo "Usage: $0 {init|acquire|release|heartbeat|cleanup}"
        exit 1
        ;;
esac
```
