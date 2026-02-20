import asyncio
import signal

import structlog

logger = structlog.get_logger()


class WorkerRuntime:
    """Skeleton worker runtime. Implements graceful shutdown."""

    def __init__(self, queue_name: str = "cpu_queue"):
        self._queue_name = queue_name
        self._running = False

    async def start(self):
        self._running = True
        logger.info("worker_started", queue=self._queue_name)

        loop = asyncio.get_running_loop()
        for sig in (signal.SIGINT, signal.SIGTERM):
            loop.add_signal_handler(sig, self._request_shutdown)

        while self._running:
            await asyncio.sleep(1.0)

        logger.info("worker_stopped", queue=self._queue_name)

    def _request_shutdown(self):
        logger.info("worker_shutdown_requested")
        self._running = False
