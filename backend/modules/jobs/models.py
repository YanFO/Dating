from dataclasses import dataclass, field
from typing import Any, Optional

from utils.time import utcnow, format_iso


@dataclass
class Job:
    job_id: str
    job_type: str
    status: str = "PENDING"  # PENDING -> RUNNING -> SUCCEEDED | FAILED | CANCELED
    progress: int = 0
    result: Optional[Any] = None
    error_summary: Optional[str] = None
    retry_count: int = 0
    created_at: str = field(default_factory=lambda: format_iso(utcnow()))
    updated_at: str = field(default_factory=lambda: format_iso(utcnow()))
