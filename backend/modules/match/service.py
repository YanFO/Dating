"""Match 業務邏輯服務

管理用戶的約會管線（Active Pipeline），提供 CRUD 操作。
使用 PostgreSQL 持久化，透過 SQLAlchemy async session 操作。
"""

import structlog
from sqlalchemy import select
from sqlalchemy.ext.asyncio import async_sessionmaker

from infra.database.models import Match as MatchRow
from modules.match.errors import MatchNotFound
from modules.match.models import MatchRecord
from services.id_service import generate_cuid

logger = structlog.get_logger()


class MatchService:
    """Match 管線服務

    提供約會對象的新增、列表、更新、刪除功能。
    所有操作均持久化至 PostgreSQL matches 表。
    """

    def __init__(self, session_factory: async_sessionmaker):
        # SQLAlchemy async session 工廠
        self._sf = session_factory

    def _row_to_model(self, row: MatchRow) -> MatchRecord:
        """將 ORM 行轉換為領域模型"""
        return MatchRecord(
            match_id=row.id,
            user_id=row.user_id,
            name=row.name,
            context_tag=row.context_tag,
            status=row.status,
            created_at=row.created_at.isoformat() if row.created_at else "",
            updated_at=row.updated_at.isoformat() if row.updated_at else "",
        )

    async def list_matches(self, user_id: str, request_id: str) -> list[MatchRecord]:
        """列出用戶所有 match 記錄，按建立時間倒序"""
        log = logger.bind(request_id=request_id, feature="match")
        async with self._sf() as session:
            stmt = (
                select(MatchRow)
                .where(MatchRow.user_id == user_id)
                .order_by(MatchRow.created_at.desc())
            )
            result = await session.execute(stmt)
            rows = result.scalars().all()
        log.info("list_matches", count=len(rows))
        return [self._row_to_model(r) for r in rows]

    async def create_match(
        self,
        user_id: str,
        name: str,
        context_tag: str | None,
        request_id: str,
    ) -> MatchRecord:
        """新增一筆 match 記錄並寫入資料庫"""
        log = logger.bind(request_id=request_id, feature="match")
        row = MatchRow(
            id=generate_cuid(),
            user_id=user_id,
            name=name,
            context_tag=context_tag,
            status="active",
        )
        async with self._sf() as session:
            session.add(row)
            await session.commit()
            await session.refresh(row)
        log.info("match_created", match_id=row.id, name=name)
        return self._row_to_model(row)

    async def update_match(
        self,
        user_id: str,
        match_id: str,
        request_id: str,
        name: str | None = None,
        context_tag: str | None = None,
        status: str | None = None,
    ) -> MatchRecord:
        """更新指定 match 記錄（僅更新有提供的欄位）"""
        log = logger.bind(request_id=request_id, feature="match")
        async with self._sf() as session:
            stmt = select(MatchRow).where(
                MatchRow.id == match_id,
                MatchRow.user_id == user_id,
            )
            result = await session.execute(stmt)
            row = result.scalar_one_or_none()
            if not row:
                raise MatchNotFound(f"Match {match_id} not found")

            if name is not None:
                row.name = name
            if context_tag is not None:
                row.context_tag = context_tag
            if status is not None:
                row.status = status
            await session.commit()
            await session.refresh(row)
        log.info("match_updated", match_id=match_id)
        return self._row_to_model(row)

    async def delete_match(self, user_id: str, match_id: str, request_id: str) -> None:
        """刪除指定 match 記錄"""
        log = logger.bind(request_id=request_id, feature="match")
        async with self._sf() as session:
            stmt = select(MatchRow).where(
                MatchRow.id == match_id,
                MatchRow.user_id == user_id,
            )
            result = await session.execute(stmt)
            row = result.scalar_one_or_none()
            if not row:
                raise MatchNotFound(f"Match {match_id} not found")

            await session.delete(row)
            await session.commit()
        log.info("match_deleted", match_id=match_id)
