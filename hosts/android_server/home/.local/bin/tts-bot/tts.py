"""Text-to-speech playback via Termux commands."""

import logging
import subprocess

log = logging.getLogger(__name__)


def speak(text: str) -> None:
    """Speak text aloud via Termux TTS.

    Raises subprocess.CalledProcessError on failure.
    """
    log.info("Speaking: %s", text[:80])
    subprocess.run(["termux-tts-speak", text], check=True)
