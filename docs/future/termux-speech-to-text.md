# Termux Speech-to-Text — Voice Input on Android

**Status:** ⏸️ Future feature. No code exists yet.

**Goal:** Enable voice-driven interaction on the Android/Termux host — dictation, voice-command execution, and speech-to-text piped into scripts and LLMs.

---

## Prerequisites

`termux-api` is already installed (`pkg install termux-api` in `install.sh`), but **the Termux:API Android app** is a separate requirement. Unlike the CLI package, the app must be sideloaded from F-Droid:

- [Termux:API on F-Droid](https://f-droid.org/packages/com.termux.api/)

Without it, `termux-speech-to-text` fails with a "Not allowed" / "API not available" error.

### Language Considerations

`termux-speech-to-text -l <code>` supports any language the Android speech recognizer handles. For this host:

| Language | Code | Use |
|----------|------|-----|
| Portuguese (BR) | `pt-BR` | Native dictation |
| English | `en` | Technical commands, LLM prompts |

---

## Architecture

```
┌─────────────┐    ┌──────────────────────┐    ┌────────────────┐
│  Microphone  │───▶│  termux-speech-to-text│───▶│  stdout (text) │
│  (Android)   │    │  (Termux:API)         │    │                 │
└─────────────┘    └──────────────────────┘    └────┬───────────┘
                                                     │
                            ┌────────────────────────┼──────────────┐
                            ▼                        ▼              ▼
                     ┌────────────┐          ┌────────────┐  ┌──────────┐
                     │ Clipboard  │          │   File     │  │ LLM/CMD  │
                     │ (colar em  │          │  (nota de  │  │ (pipe pra│
                     │  qualquer  │          │   voz)     │  │  Hermes) │
                     │  app)      │          │            │  │          │
                     └────────────┘          └────────────┘  └──────────┘
```

---

## Proposed Scripts

All scripts go into `hosts/android/home/.local/bin/`, following the existing pattern. They get deployed via `configure.sh`'s section 7 (copy scripts step).

### 1. `termux-stt` — Dictate to stdout

Simple wrapper with language selection, timeout, and error handling.

```bash
# termux-stt — Record speech and output text
# Usage: termux-stt [-l lang] [-t timeout] [--copy]
#
# Options:
#   -l LANG     Language (default: pt-BR)
#   -t SECONDS  Recording timeout (default: 10)
#   --copy      Also copy result to clipboard
#   --silent    No bell/notification feedback
#
# Examples:
#   termux-stt                      # Dictate in Portuguese
#   termux-stt -l en -t 30          # English, longer recording
#   termux-stt --copy               # Dictate + auto-copy to clipboard
#   termux-stt | pbcopy             # Pipe to clipboard (Termux)
#   echo "$(termux-stt)" >> note.md # Append to file
```

### 2. `termux-stt-clip` — Dictate → Clipboard

Specialised one-liner: record speech, paste result into Android clipboard via `termux-clipboard-set`. Use this from any app that supports text input — record, switch to the app, paste.

### 3. `termux-stt-note` — Dictate → Timestamped Note

Append transcribed text to `~/notes/voice-notes.md` (or a configurable path) with a timestamp. Useful for capturing thoughts on the go.

```bash
# termux-stt-note — Append dictated text to a voice notes file
# Creates ~/notes/voice-notes.md with ISO 8601 timestamps.
# Usage: termux-stt-note [options passed to termux-stt]
```

### 4. `termux-stt-run` — Dictate → Execute as Command

Record speech, parse the transcription, and run it as a shell command. **Use with caution — the user confirms before execution.** This is the bridge to full voice-controlled Termux.

```bash
# termux-stt-run — Say a command, run it
# Usage: termux-stt-run [-l lang]
#
# Flow:
#   1. Open mic, transcribe
#   2. Show the transcribed command
#   3. Prompt [Enter to run | Ctrl-C to cancel]
#   4. Execute and show output
```

---

## Files to Create

| File | Purpose |
|------|---------|
| `hosts/android/home/.local/bin/termux-stt` | Core STT wrapper |
| `hosts/android/home/.local/bin/termux-stt-clip` | Dictate → clipboard shorthand |
| `hosts/android/home/.local/bin/termux-stt-note` | Dictate → timestamped note |
| `hosts/android/home/.local/bin/termux-stt-run` | Dictate → shell command |

## Files to Modify

| File | Change |
|------|--------|
| `hosts/android/bootstrap/install.sh` | No changes needed (termux-api already installed) |
| `hosts/android/bootstrap/configure.sh` | No changes needed (section 7 auto-copies `home/.local/bin/`) |
| `hosts/android/README.md` | Add STT scripts to the scripts table |

---

## Implementation Tasks

### Task 1: Create `termux-stt` (Core Wrapper)

The foundation script that all others call (or share logic with).

**Design:**

```bash
#!/data/data/com.termux/files/usr/bin/bash
# termux-stt — Record speech and output text via Termux:API
# Uses Android's built-in speech recognition (offline capable).

set -euo pipefail

LANG="pt-BR"
TIMEOUT=10
COPY=false
SILENT=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [-l LANG] [-t SECONDS] [--copy] [--silent]

Record speech and print transcribed text to stdout.

Options:
  -l LANG     Recognition language (default: pt-BR)
  -t SECONDS  Max recording time (default: 10)
  --copy      Also copy to clipboard via termux-clipboard-set
  --silent    Suppress notification feedback
  -h          Show help
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -l) LANG="$2"; shift 2 ;;
    -t) TIMEOUT="$2"; shift 2 ;;
    --copy) COPY=true; shift ;;
    --silent) SILENT=true; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown: $1" >&2; usage ;;
  esac
done

# Verify termux-speech-to-text is available
if ! command -v termux-speech-to-text &>/dev/null; then
  echo "Error: termux-speech-to-text not found." >&2
  echo "  Install: pkg install termux-api" >&2
  echo "  Also install Termux:API app from F-Droid." >&2
  exit 1
fi

# Check Termux:API app is accessible (not just the CLI)
# termux-speech-to-text returns "Not allowed" if app isn't installed
if ! $SILENT; then
  termux-notification \
    --title "🎤 Listening..." \
    --content "Speaking in $LANG (${TIMEOUT}s)" \
    --priority low \
    --alert-once || true
fi

# Capture transcription
TEXT="$(termux-speech-to-text -l "$LANG" --timeout "$TIMEOUT" 2>/dev/null)" || {
  echo "Error: Speech recognition failed." >&2
  echo "  Is the Termux:API app installed?" >&2
  exit 2
}

if [[ -z "$TEXT" ]]; then
  echo "Error: No speech detected or timed out." >&2
  exit 3
fi

if ! $SILENT; then
  termux-notification \
    --title "✅ Transcribed" \
    --content "${TEXT:0:100}" \
    --priority low \
    --alert-once || true
fi

# Output text
echo "$TEXT"

# Copy to clipboard if requested
if $COPY; then
  echo -n "$TEXT" | termux-clipboard-set
fi
```

### Task 2: Create `termux-stt-clip` (Dictate → Clipboard)

Thin wrapper, ~20 lines. Calls `termux-stt --copy --silent`.

### Task 3: Create `termux-stt-note` (Dictate → Voice Notes)

Appends to `$HOME/notes/voice-notes.md`, creates it on first run. Each entry:

```markdown
## 2026-06-24T14:30:00-03:00

Transcribed text here...

---
```

### Task 4: Create `termux-stt-run` (Dictate → Shell Command)

Higher risk, needs user confirmation. Flow:

1. Run `termux-stt --silent` to get transcribed command
2. Display: `Run: <transcribed text>? [Enter=yes / Ctrl-C=no]`
3. If confirmed, eval the command
4. Show output, offer to run again

### Task 5: Update `hosts/android/README.md`

Add STT scripts to the scripts table:

```
| `termux-stt` | Record speech → stdout (dictation) |
| `termux-stt-clip` | Record speech → Android clipboard |
| `termux-stt-note` | Record speech → timestamped voice note |
| `termux-stt-run` | Record speech → run as shell command |
```

---

## Advanced / Future Use Cases

Once the base scripts exist, these integrations layer on top:

### Hermes Agent Voice Input

Alias that pipes STT into a Hermes query:

```bash
alias hstt='termux-stt -l pt-BR | xargs -0 hermes ask'
```

Or a script that opens mic, transcribes, and sends the text as a Telegram message to the agent:

```bash
# termux-hermes-voice — Speak a message to Hermes via Telegram
termux-stt --silent | while IFS= read -r text; do
  termux-telegram-send "$text"
done
```

### Offline Recognition

Android's built-in speech recognition works offline when language packs are downloaded (Settings → Language & Input → Speech → Offline speech recognition). The plan assumes online recognition by default, but offline fallback is automatic if the pack is installed.

### Multiple Languages

A rapid-switch script that lets you toggle languages mid-session:

```bash
termux-stt-lang en    # switch to English
termux-stt-lang pt-BR # switch back to Portuguese
```

Implement as a state file at `$HOME/.termux/stt-lang` read by all STT scripts.

---

## Risks & Caveats

- **Termux:API app required** — not installable via `pkg`. Must be side-loaded from F-Droid. Document this prominently.
- **Mic permission** — Android will prompt for microphone access on first invocation.
- **Background recording** — Android aggressively kills background processes. `termux-wake` (wakelock) may be needed for longer recordings.
- **Recognition accuracy** — depends on Android's speech recognizer (varies by device, language, and noise). No cloud fallback for better accuracy — consider an offline model if needed.
- **`termux-stt-run` safety** — transcribed commands can be misinterpreted. Always require confirmation, never auto-execute.
- **Notification sounds** — `termux-speech-to-text` blocks until recognition completes. The notification approach (start/stop beacons) helps with UX but depends on `termux-notification` being available.
