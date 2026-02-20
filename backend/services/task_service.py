from dataclasses import dataclass, field
from typing import Any, Optional

import structlog

from services.id_service import generate_job_id
from utils.time import utcnow, format_iso

logger = structlog.get_logger()


@dataclass
class TaskRecord:
    task_id: str
    task_type: str
    status: str = "PENDING"
    progress: int = 0
    result: Optional[Any] = None
    error: Optional[str] = None
    created_at: str = field(default_factory=lambda: format_iso(utcnow()))


class TaskService:
    """In-memory task tracking. Will be backed by MongoDB in Phase 4."""

    def __init__(self):
        self._tasks: dict[str, TaskRecord] = {}

    async def submit(self, task_type: str, payload: dict) -> str:
        task_id = generate_job_id()
        self._tasks[task_id] = TaskRecord(task_id=task_id, task_type=task_type)
        logger.info("task_submitted", task_id=task_id, task_type=task_type)
        return task_id

    async def get_status(self, task_id: str) -> Optional[TaskRecord]:
        return self._tasks.get(task_id)

    async def update_status(
        self, task_id: str, status: str, progress: int = 0
    ) -> None:
        task = self._tasks.get(task_id)
        if task:
            task.status = status
            task.progress = progress
