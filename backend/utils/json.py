from datetime import datetime
from typing import Any

import orjson


def _default(obj: Any) -> Any:
    if isinstance(obj, datetime):
        return obj.isoformat()
    raise TypeError(f"Object of type {type(obj)} is not JSON serializable")


def dumps(obj: Any) -> str:
    return orjson.dumps(obj, default=_default).decode()


def loads(data: str | bytes) -> Any:
    return orjson.loads(data)
