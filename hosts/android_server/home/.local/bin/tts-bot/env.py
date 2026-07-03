"""Load configuration from .env file."""

import os
from pathlib import Path

HERE = Path(__file__).parent
ENV_FILE = HERE / ".env"


def _get_user_ids(raw: str) -> set:
    """Parse comma-separated user IDs.

    Raises ValueError with a clear message on malformed input.
    """
    allowed = set()
    for part in raw.split(","):
        part = part.strip()
        if not part:
            continue
        try:
            allowed.add(int(part))
        except ValueError:
            raise ValueError(
                f"ALLOWED_USER_IDS: could not parse \"{part}\" to integer"
            )
    if not allowed:
        raise ValueError("ALLOWED_USER_IDS must contain at least one ID")
    return allowed


def load() -> dict:
    """Load and validate .env. Returns dict with token and allowed_user_ids."""
    from dotenv import load_dotenv

    load_dotenv(ENV_FILE)

    token = os.environ.get("TELEGRAM_BOT_TOKEN", "").strip()
    if not token:
        raise ValueError("TELEGRAM_BOT_TOKEN is required")

    raw = os.environ.get("ALLOWED_USER_IDS", "").strip()
    if not raw:
        raise ValueError("ALLOWED_USER_IDS is required (comma-separated)")

    return {"token": token, "allowed_user_ids": _get_user_ids(raw)}
