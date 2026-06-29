# TTS Server — Text-to-Speech HTTP Service on Android

**Status:** ⏸️ Planned. No code exists yet.

**Goal:** Expose `termux-tts-speak` as a lightweight HTTP server on the Android/Termux host, so any machine on the local network can send text and have the Android device speak it aloud.

---

## Problem Statement

When a message arrives from an automation, alert, or AI agent, there is no way to make the Android device in the homelab speak it aloud. Currently, alerts go to notifications (silent) or require SSHing in and running `termux-tts-speak` manually. The Android device has a speaker and a working TTS engine — but no network-accessible TTS endpoint.

## Solution

A single-file Python HTTP server that listens on a local port, accepts JSON via POST, and calls `termux-tts-speak` with the provided parameters. Managed as a `runit` service via `termux-services` so it auto-starts and stays up. All configuration lives in the dotfiles repo under `hosts/android/`.

## User Stories

1. As a homelab operator, I want to POST text to an HTTP endpoint on the Android device, so that the device speaks the message aloud.
2. As a homelab operator, I want to specify the language (e.g. `pt-BR`, `en`) in the request, so that the TTS engine uses the correct pronunciation.
3. As a homelab operator, I want to adjust the speech rate and pitch, so that urgent messages sound different from casual ones.
4. As a homelab operator, I want to select the audio stream (e.g. `ALARM`, `NOTIFICATION`, `MUSIC`), so that the message plays through the intended audio channel.
5. As a homelab operator, I want the server to auto-restart if it crashes, so that the endpoint is always available.
6. As a homelab operator, I want the server to only accept requests from the local subnet, so that random internet traffic can't trigger speech.
7. As a homelab operator, I want the server to log requests to stdout, so that I can tail logs for debugging.
8. As a maintainer, I want the service to be bootstrapped from the dotfiles repo, so that a fresh Termux install gets the TTS server automatically.

## Implementation Decisions

### Architecture

```
┌──────────────┐    POST /tts     ┌───────────────────┐    exec       ┌─────────────────────┐
│ Homelab host │ ────────────────▶│  ttsd (Python)    │──────────────▶│ termux-tts-speak    │
│ (curl, cron, │                  │  :<random-port>   │               │ (Android TTS engine)│
│  script...)  │                  │  JSON body        │               └─────────────────────┘
└──────────────┘                  └───────────────────┘
                                        │
                                        ▼
                                  ┌──────────────┐
                                  │  runit/sv    │
                                  │  auto-start  │
                                  │  auto-respawn│
                                  └──────────────┘
```

### Interface

**HTTP endpoint:** `POST /tts`

**Request body** (JSON):

| Field    | Type   | Required | Default      | Description |
|----------|--------|----------|--------------|-------------|
| `text`   | string | **yes**  | —            | Text to speak |
| `lang`   | string | no       | device default | Language code (e.g. `pt-BR`, `en`) |
| `engine` | string | no       | device default | TTS engine name (list with `termux-tts-engines`) |
| `region` | string | no       | —            | Region of the language |
| `variant`| string | no       | —            | Variant of the language |
| `pitch`  | float  | no       | 1.0          | Pitch (1.0 = normal) |
| `rate`   | float  | no       | 1.0          | Speech rate (1.0 = normal) |
| `stream` | string | no       | `NOTIFICATION` | Audio stream: `ALARM`, `MUSIC`, `NOTIFICATION`, `RING`, `SYSTEM`, `VOICE_CALL` |

**Response:**
- `200 OK` — Text spoken successfully. Body: `{"status": "ok", "text": "<spoken text>"}`
- `400 Bad Request` — Missing `text` field. Body: `{"error": "Missing required field: text"}`
- `500 Internal Server Error` — `termux-tts-speak` failed. Body: `{"error": "<stderr output>"}`

### Network Security

- Server binds to `0.0.0.0:<random-port>`
- Auto-detects the local subnet from the active interface (e.g. `192.168.1.0/24`)
- Rejects requests from IPs outside the detected subnet with `403 Forbidden`
- No authentication token — relies on network-layer trust

### Port Assignment

- A random high port is chosen at first start
- The chosen port is persisted to `$HOME/.termux/ttsd-port`
- On restart, reads the port from the file (stable across reboots)
- If the file is missing, generates a new random port

### Service Management

- `runit` service directory: `$PREFIX/var/service/ttsd/`
- Service script: `run` — starts the Python server
- Logging: `sv log ttsd` via `runit`'s built-in log service

### Files in dotfiles repo

| File | Purpose |
|------|---------|
| `hosts/android/home/.local/bin/termux-tts-server` | Python HTTP server script |
| `hosts/android/var/service/ttsd/run` | runit service run script |
| `hosts/android/var/service/ttsd/log/run` | runit log service script |
| `hosts/android/README.md` | Add TTS server to the scripts and services tables |

### Existing scripts/services that stay unchanged

- `bootstrap/install.sh` — No changes (Python and `termux-api` already installed)
- `bootstrap/configure.sh` — Section 7 already copies `home/.local/bin/` (TTS scripts picked up automatically)

## Testing Decisions

This is a hardware-integration feature with no meaningful unit-test seam — the entire value is that `termux-tts-speak` actually speaks on the Android device. Testing strategy:

1. **Functional test (on-device):** After deploy, `curl -X POST -H "Content-Type: application/json" -d '{"text": "hello world"}' http://<android-ip>:<port>/tts` — verify the device speaks.
2. **Health check:** `GET /health` returns `200 OK` with `{"status": "running"}`.
3. **Outside-subnet rejection:** Spoof `X-Forwarded-For` or simulate from a different subnet — verify `403`.
4. **Missing text:** POST with empty body or missing `text` — verify `400`.

No automated CI tests since this requires a physical Android device with Termux and speaker.

## Out of Scope

- **Authentication tokens / API keys** — network-layer trust is sufficient for a homelab
- **TTS queue** — concurrent requests are handled serially (Android TTS is single-channel)
- **Web interface / dashboard** — command-line and curl-only
- **Speech-to-Text** — covered by separate `termux-stt` feature
- **TTS via MQTT / WebSocket** — HTTP-only for now
- **Per-request audio file generation** — real-time speak only, no .wav/.mp3 output

## Implementation Phases

### Phase 1: Core Python Server

**Files:**
- `hosts/android/home/.local/bin/termux-tts-server`

**Definition of Done:**
- Server starts, binds to a random port, writes port file
- `POST /tts` with `{"text": "..."}` calls `termux-tts-speak` and speaks
- Optional parameters (lang, pitch, rate, stream, engine, region, variant) are forwarded correctly
- `GET /health` returns `200`
- Subnet filtering blocks external IPs
- Missing `text` returns `400`
- Server handles `SIGTERM` gracefully (stop speaking, exit clean)

### Phase 2: runit Service

**Files:**
- `hosts/android/var/service/ttsd/run`
- `hosts/android/var/service/ttsd/log/run`

**Definition of Done:**
- `sv up ttsd` starts the server
- `sv down ttsd` stops it gracefully
- `sv status ttsd` shows `run`
- Server auto-restarts if killed (runit default behaviour)
- stdout logs captured via `log/run`

### Phase 3: Documentation & Bootstrap

**Files:**
- `hosts/android/README.md` (update)

**Definition of Done:**
- README updated with TTS server in the scripts table and services table
- Port and endpoint documented
- Example `curl` commands included

## Further Notes

- The `termux-tts-speak` executable ships with `termux-api` package — it is already installed on this host.
- The Termux:API Android app is **not required** for TTS (unlike STT which needs it). TTS works with just the CLI package.
- Android speech rate and pitch behave differently per engine. `1.0` is the system normal, but some engines may respond differently.
- The `NOTIFICATION` stream plays at media volume, not notification volume, on most Android devices. If louder output is needed, use `MUSIC` stream.
- If text contains special characters, the subprocess call must properly escape them. Python's `subprocess.run` with `args` list handles this automatically.
