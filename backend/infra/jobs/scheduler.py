import structlog

logger = structlog.get_logger()


class JobScheduler:
    """Skeleton job scheduler."""

    async def schedule(self, job_id: str, run_at: float) -> None:
        logger.debug("job_scheduled_noop", job_id=job_id)

    async def cancel(self, job_id: str) -> None:
        logger.debug("job_cancelled_noop", job_id=job_id)
