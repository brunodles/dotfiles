"""Text-to-speech and audio playback via Termux commands."""

import logging
import subprocess
from pathlib import Path

log = logging.getLogger(__name__)


def speak(text: str) -> None:
    """Speak text aloud via Termux TTS.

    Raises subprocess.CalledProcessError on failure.
    """
    log.info("Speaking: %s", text[:80])
    subprocess.run(["termux-tts-speak", text], check=True)


def play(audio_path: Path) -> None:
    """Play an audio file via Termux media player.

    Args:
        audio_path: Path to a downloaded audio file (OGG, MP3, etc.).

    Raises subprocess.CalledProcessError on failure.
    """
    log.info("Playing: %s", audio_path.name)
    subprocess.run(["termux-media-player", "play", str(audio_path)], check=True)
