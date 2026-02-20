import time
from datetime import datetime, timezone


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def timestamp_ms() -> int:
    return int(time.time() * 1000)


def format_iso(dt: datetime) -> str:
    return dt.isoformat()
