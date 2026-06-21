# Agent Queue — Hermes Integration Feasibility

## Context

A full design for a queue-based multi-agent Git coordination system exists at
`docs/agent-queue-design.md` (Approach A: file-based lock + JSON task queue).
This document evaluates whether it can be integrated into Hermes Agent.

## Current Hermes Capabilities

| Feature | How it works | Queue relevance |
|---------|-------------|-----------------|
| `delegate_task` | Spawns isolated subagents with own context + tools | ✅ Can parallelize, but no coordination |
| `delegate_task(background=true)` | Async subagents that report back when done | ✅ Background work possible, but no queue |
| `cronjob` | Scheduled job with skill loading | ✅ Can auto-enqueue tasks from cron |
| `terminal` | Shell commands with persistent session | ✅ Can run `git-queue` script directly |
| `execute_code` | Python with `from hermes_tools import ...` | ✅ Can implement queue logic in Python |
| Concurrent tasks | Multiple delegations via `tasks[]` | ⚠️ They run in parallel with no locking |
| Session isolation | Each session has own state, env, cwd | ⚠️ Major — sessions can't see each other |

## Integration Approaches

### Approach 1: Script-Based (Low integration, high feasibility)

Use the `scripts/git-queue` bash script as-is. Each Hermes session calls:

```bash
export GIT_QUEUE_AGENT=hermes GIT_QUEUE_TASK=TASK-003
bash scripts/git-queue acquire
# ... make changes ...
bash scripts/git-queue release
```

**Pros:** Zero Hermes changes. Works now. Leverages existing terminal tool.
**Cons:** No enforcement — agent can forget to call acquire/release. No UI.
Relying on agent memory to follow protocol.

### Approach 2: Hermes Plugin (`hermes queue` CLI)

Add a `queue` toolset or plugin that wraps the queue protocol in a first-class
Hermes interface:

```bash
# Hypothetical Hermes CLI
hermes queue acquire --task TASK-003
hermes queue release --task TASK-003
hermes queue status
hermes queue add --file task.json
```

**Pros:** Enforceable — tools can check queue state before file writes.
Hermes could automatically acquire a queue lock before `delegate_task` that
mutates the repo. Transparent to the user.
**Cons:** Requires Hermes core changes (new tool, new CLI command, config).
Moderate dev effort (a few days).

### Approach 3: Automatic Lock via `patch` / `write_file` middleware

Insert a queue check into Hermes's file-mutation tools (`patch`, `write_file`,
`terminal` with git commands). Before any write to the repo, Hermes checks if
the task's `files[]` are not in conflict.

**Pros:** Zero-friction — agent doesn't need to remember. Locks are automatic.
**Cons:** Requires deep hooks into Hermes's tool system. High complexity.
Could break existing workflows. Heavy instrumentation for something that's
only needed during multi-agent repo work.

## Feasibility Verdict

### ✅ Feasible — Immediate: Approach 1

The queue scripts (`scripts/git-queue`, `scripts/git-queue-pre-push`) can be
used right now in any Hermes session by calling terminal tool. The design
assumes shared filesystem — which is true if all agents run on the same host
(e.g., VPS) or mount the repo via NFS/Tailscale SSH.

The pre-push hook integrates at the Git level as an **enforcement layer**:
even if an agent forgets the queue, a direct `git push` will be rejected.

### ⚠️ Feasible with caveats — Approach 2: Medium effort

Adding a `hermes queue` CLI and toolset is doable but requires:
1. A new config section in `config.yaml` for queue settings (lock TTL, agent ID)
2. A `queue` toolset with `acquire`, `release`, `status`, `add`
3. Session-scoped lock state (track which lock each session holds)
4. Appropriate error messages when queue prevents an operation

This would be a **plugin** or a **built-in toolset** — both are supported
architectures in Hermes.

### ❌ Not recommended: Approach 3

Automatic locking via tool middleware is overengineered for the use case and
risks breaking Hermes's core reliability. The queue should be opt-in, not
silent.

## Key Limitations

| Limitation | Impact | Workaround |
|-----------|--------|------------|
| **Shared filesystem required** | Agents on different hosts can't `flock` the same file | Use hybrid approach: `.git-queue/` is committed to git; agents pull, work, push |
| **No distributed lock** | `flock` is POSIX local, not network | Combine with git push/pull as transport (design's hybrid mode) |
| **Heartbeat requires background process** | Agent must run a periodic heartbeat while holding lock | Use `terminal(background=true)` with a watcher, or accept 10min TTL risk |
| **No priority queue** | FIFO only | Patch the script to add priority field + sort |
| **Hermes sessions are ephemeral** | A background task can be killed mid-edit | Lock auto-releases on process death (flock property). Task stays `acquired` — manual recovery needed |

## Hermes-Specific Design Suggestions

If implementing as a Hermes feature (Approach 2):

```yaml
# config.yaml
queue:
  enabled: true
  lock_ttl_seconds: 600
  agent_id: "hermes-vps"         # unique per agent instance
  transport: "shared-fs"         # or "git" for distributed
  auto_acquire: false            # opt-in only
```

New toolset `queue` with tools:
- `queue_acquire(task_id=None)` — acquire queue lock, optionally for specific task
- `queue_release()` — mark current task complete, release lock
- `queue_status()` — show queue state (pending, running, blocked)
- `queue_add(task_definition)` — enqueue a new task

Integration with `delegate_task(background=true)`:
- Before dispatching a background task that modifies the repo, Hermes could
  auto-enqueue it
- The subagent would acquire the lock when it starts work

## Recommendation

**Start with Approach 1** (use scripts as-is) and let the real-world experience
inform whether Approach 2 (Hermes plugin/CLI) is worth building. The scripts
are already written, tested for syntax, and ready to use.

If the user hits friction (agents forgetting to queue, stale locks, recovery
headaches), then invest in a Hermes plugin that automates the protocol.
