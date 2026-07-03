"""Raw HTTP Telegram bot — text-to-speech dispatch."""

import logging
from pathlib import Path

import requests

import env
import tts

API = "https://api.telegram.org/bot"
log = logging.getLogger(__name__)


def poll() -> None:
    """Run polling loop. Blocks forever."""
    cfg = env.load()
    token = cfg["token"]
    allowed = cfg["allowed_user_ids"]
    offset = 0

    log.info("Bot started. Allowed users: %s", allowed)

    while True:
        try:
            resp = requests.get(
                f"{API}{token}/getUpdates",
                params={"offset": offset, "timeout": 60},
                timeout=70,
            )
            resp.raise_for_status()
            data = resp.json()

            if not data.get("ok"):
                log.warning("API returned ok=false: %s", data)
                continue

            for update in data.get("result", []):
                offset = update["update_id"] + 1
                msg = update.get("message")
                if not msg:
                    continue

                user_id = msg["from"]["id"]
                if user_id not in allowed:
                    log.info("Ignored message from %d (unauthorized)", user_id)
                    continue

                _handle_message(token, msg)

        except requests.RequestException as e:
            log.error("Poll request failed: %s", e)


def _handle_message(token: str, msg: dict) -> None:
    """Dispatch a single message."""
    chat_id = msg["chat"]["id"]

    if "voice" in msg:
        log.info("Voice from %d", msg["from"]["id"])
        _handle_audio(token, chat_id, msg["voice"]["file_id"])
        return

    if "audio" in msg:
        log.info("Audio from %d", msg["from"]["id"])
        _handle_audio(token, chat_id, msg["audio"]["file_id"])
        return

    if "text" in msg:
        text = msg["text"]
        log.info("Text from %d: %s", msg["from"]["id"], text[:80])
        try:
            tts.speak(text)
        except Exception as e:
            log.error("TTS failed: %s", e)
            _reply(token, chat_id, f"TTS failed: {e}")
        return

    log.info("Ignored unsupported message type from %d", msg["from"]["id"])


def _handle_audio(token: str, chat_id: int, file_id: str) -> None:
    """Download an audio/voice file and play it via Termux."""
    try:
        resp = requests.get(
            f"{API}{token}/getFile",
            params={"file_id": file_id},
            timeout=15,
        )
        resp.raise_for_status()
        data = resp.json()

        if not data.get("ok") or "result" not in data:
            log.warning("getFile failed: %s", data)
            _reply(token, chat_id, "Failed to resolve file")
            return

        file_path = data["result"]["file_path"]
        download_url = f"{API}{token}/{file_path}"

        audio_resp = requests.get(download_url, timeout=30)
        audio_resp.raise_for_status()

        # Save as .oga (Telegram voice is OGG Opus)
        dest = Path(f"/tmp/tts_{file_id}.oga")
        dest.write_bytes(audio_resp.content)

        tts.play(dest)
        dest.unlink(missing_ok=True)

    except requests.RequestException as e:
        log.error("Audio download failed: %s", e)
        _reply(token, chat_id, f"Audio download failed: {e}")
    except Exception as e:
        log.error("Audio playback failed: %s", e)
        _reply(token, chat_id, f"Audio playback failed: {e}")


def _reply(token: str, chat_id: int, text: str) -> None:
    """Send a reply to the user (errors only)."""
    try:
        requests.post(
            f"{API}{token}/sendMessage",
            json={"chat_id": chat_id, "text": text},
            timeout=10,
        )
    except Exception as e:
        log.warning("Failed to send reply: %s", e)
