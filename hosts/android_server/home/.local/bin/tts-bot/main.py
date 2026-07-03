"""TTS Bot — Telegram text-to-speech for Android/Termux."""

import logging
import sys

from bot import poll

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    stream=sys.stdout,
)


def main() -> None:
    try:
        poll()
    except KeyboardInterrupt:
        logging.info("Shutting down")
    except Exception as e:
        logging.exception("Fatal error: %s", e)
        sys.exit(1)


if __name__ == "__main__":
    main()
