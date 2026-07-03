"""Load configuration from .env file."""

import os
from pathlib import Path

HERE = Path(__file__).parent
ENV_FILE = HERE / ".env"


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

    allowed = [int(x.strip()) for x in raw.split(",") if x.strip()]
    if not allowed:
        raise ValueError("ALLOWED_USER_IDS must contain at least one ID")

    return {"token": token, "allowed_user_ids": set(allowed)}
