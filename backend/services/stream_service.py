import asyncio
from typing import Any

import structlog

logger = structlog.get_logger()


class StreamService:
    """Pub/sub event bus for WebSocket streaming using asyncio.Queue."""

    def __init__(self):
        self._channels: dict[str, list[asyncio.Queue]] = {}

    async def subscribe(self, channel_id: str) -> asyncio.Queue:
        queue: asyncio.Queue = asyncio.Queue(maxsize=256)
        if channel_id not in self._channels:
            self._channels[channel_id] = []
        self._channels[channel_id].append(queue)
        logger.debug("stream_subscribed", channel_id=channel_id)
        return queue

    async def publish(self, channel_id: str, event: Any) -> None:
        subscribers = self._channels.get(channel_id, [])
        dead = []
        for q in subscribers:
            try:
                q.put_nowait(event)
            except asyncio.QueueFull:
                logger.warning("stream_queue_full", channel_id=channel_id)
                dead.append(q)
        for q in dead:
            subscribers.remove(q)

    async def unsubscribe(self, channel_id: str, queue: asyncio.Queue) -> None:
        subscribers = self._channels.get(channel_id, [])
        if queue in subscribers:
            subscribers.remove(queue)
        if not subscribers and channel_id in self._channels:
            del self._channels[channel_id]
        logger.debug("stream_unsubscribed", channel_id=channel_id)
