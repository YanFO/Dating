from typing import Optional

import structlog

from modules.jobs.models import Job
from services.id_service import generate_job_id

logger = structlog.get_logger()


class JobService:
    """Skeleton job service. In-memory tracking."""

    def __init__(self):
        self._jobs: dict[str, Job] = {}

    async def create_job(self, job_type: str, payload: dict) -> Job:
        job_id = generate_job_id()
        job = Job(job_id=job_id, job_type=job_type)
        self._jobs[job_id] = job
        logger.info("job_created", job_id=job_id, job_type=job_type)
        return job

    async def get_job(self, job_id: str) -> Optional[Job]:
        return self._jobs.get(job_id)

    async def update_job(self, job_id: str, status: str, progress: int = 0) -> None:
        job = self._jobs.get(job_id)
        if job:
            job.status = status
            job.progress = progress
