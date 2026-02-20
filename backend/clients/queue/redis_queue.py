from typing import Any, Optional

import structlog

logger = structlog.get_logger()


class RedisQueue:
    """Skeleton queue client. No-op until Redis queue is needed."""

    async def enqueue(self, queue_name: str, payload: dict) -> str:
        logger.debug("queue_enqueue_noop", queue=queue_name)
        return ""

    async def dequeue(self, queue_name: str, timeout: int = 5) -> Optional[Any]:
        return None

    async def close(self) -> None:
        pass
