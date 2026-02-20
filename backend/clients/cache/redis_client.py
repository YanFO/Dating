from typing import Any, Optional

import structlog

logger = structlog.get_logger()


class RedisClient:
    """Skeleton Redis client. Returns pass-through values until Redis is needed."""

    async def get(self, key: str) -> Optional[str]:
        return None

    async def set(self, key: str, value: Any, ttl: int = 300) -> None:
        pass

    async def delete(self, key: str) -> None:
        pass

    async def close(self) -> None:
        pass
