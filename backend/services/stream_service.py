"""WebSocket 串流服务模块，基于 asyncio.Queue 实现发布/订阅事件总线。"""

import asyncio
from typing import Any

import structlog

logger = structlog.get_logger()


class StreamService:
    """基于 asyncio.Queue 的发布/订阅事件总线，用于 WebSocket 即时推送。"""

    def __init__(self):
        """初始化频道字典。"""
        self._channels: dict[str, list[asyncio.Queue]] = {}

    async def subscribe(self, channel_id: str) -> asyncio.Queue:
        """订阅指定频道，返回一个接收事件的队列。"""
        queue: asyncio.Queue = asyncio.Queue(maxsize=256)
        if channel_id not in self._channels:
            self._channels[channel_id] = []
        self._channels[channel_id].append(queue)
        logger.debug("stream_subscribed", channel_id=channel_id)
        return queue

    async def publish(self, channel_id: str, event: Any) -> None:
        """向指定频道的所有订阅者发布事件。"""
        subscribers = self._channels.get(channel_id, [])
        for q in subscribers:
            q.put_nowait(event)

    async def unsubscribe(self, channel_id: str, queue: asyncio.Queue) -> None:
        """取消订阅指定频道，并在无订阅者时清理频道。"""
        subscribers = self._channels.get(channel_id, [])
        if queue in subscribers:
            subscribers.remove(queue)
        if not subscribers and channel_id in self._channels:
            del self._channels[channel_id]
        logger.debug("stream_unsubscribed", channel_id=channel_id)
