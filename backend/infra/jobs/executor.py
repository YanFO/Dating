import structlog

logger = structlog.get_logger()


class JobExecutor:
    """Skeleton job executor with state machine:
    PENDING -> RUNNING -> SUCCEEDED | FAILED | CANCELED
    """

    async def execute(self, job_id: str, job_type: str, payload: dict) -> str:
        logger.debug("job_execute_noop", job_id=job_id, job_type=job_type)
        return "SUCCEEDED"
