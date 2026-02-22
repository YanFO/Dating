"""非同步任務管理模組的資料模型定義。"""

from dataclasses import dataclass, field
from typing import Any, Optional

from utils.time import utcnow, format_iso


@dataclass
class Job:
    """非同步任務，記錄任務 ID、類型、狀態、進度及結果等資訊。"""
    job_id: str
    job_type: str
    status: str = "PENDING"  # PENDING -> RUNNING -> SUCCEEDED | FAILED | CANCELED
    progress: int = 0
    result: Optional[Any] = None
    error_summary: Optional[str] = None
    retry_count: int = 0
    created_at: str = field(default_factory=lambda: format_iso(utcnow()))
    updated_at: str = field(default_factory=lambda: format_iso(utcnow()))
