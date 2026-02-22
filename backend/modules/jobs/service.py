"""非同步任務管理模組的核心服務，負責任務的建立、查詢與狀態更新。

使用 PostgreSQL 持久化，透過 SQLAlchemy async session 操作 jobs 表。
"""

from typing import Optional

import structlog
from sqlalchemy import select
from sqlalchemy.ext.asyncio import async_sessionmaker

from infra.database.models import Job as JobRow
from modules.jobs.models import Job
from services.id_service import generate_cuid

logger = structlog.get_logger()


class JobService:
    """任務服務，提供持久化的任務追蹤與管理。"""

    def __init__(self, session_factory: async_sessionmaker):
        self._sf = session_factory  # SQLAlchemy async session 工廠

    def _row_to_model(self, row: JobRow) -> Job:
        """將 ORM 行轉換為領域模型"""
        return Job(
            job_id=row.id,
            job_type=row.job_type,
            status=row.status,
            progress=row.progress,
            result=row.result_json,
            error_summary=row.error_summary,
            retry_count=row.retry_count,
            created_at=row.created_at.isoformat() if row.created_at else "",
            updated_at=row.updated_at.isoformat() if row.updated_at else "",
        )

    async def create_job(self, job_type: str, payload: dict) -> Job:
        """建立新任務並寫入資料庫，回傳任務物件。"""
        row = JobRow(
            id=generate_cuid(),
            job_type=job_type,
            status="PENDING",
            progress=0,
            payload_json=payload,
        )
        async with self._sf() as session:
            session.add(row)
            await session.commit()
            await session.refresh(row)
        logger.info("job_created", job_id=row.id, job_type=job_type)
        return self._row_to_model(row)

    async def get_job(self, job_id: str) -> Optional[Job]:
        """根據任務 ID 查詢任務，找不到時回傳 None。"""
        async with self._sf() as session:
            stmt = select(JobRow).where(JobRow.id == job_id)
            result = await session.execute(stmt)
            row = result.scalar_one_or_none()
        if not row:
            return None
        return self._row_to_model(row)

    async def update_job(self, job_id: str, status: str, progress: int = 0) -> None:
        """更新指定任務的狀態與進度。"""
        async with self._sf() as session:
            stmt = select(JobRow).where(JobRow.id == job_id)
            result = await session.execute(stmt)
            row = result.scalar_one_or_none()
            if row:
                row.status = status
                row.progress = progress
                await session.commit()
                logger.info("job_updated", job_id=job_id, status=status, progress=progress)
