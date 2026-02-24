"""Insights 業務邏輯服務

提供用戶的成長雷達圖數據、約會報告列表以及語音教練對話紀錄。
使用 PostgreSQL 持久化，從 date_reports 與 analysis_logs 表讀取數據。
"""

from dataclasses import asdict

import structlog
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import async_sessionmaker

from infra.database.models import AnalysisLog, DateReport as ReportRow
from modules.insights.models import DateReport, SkillScores, VoiceCoachLog
from services.id_service import generate_cuid

logger = structlog.get_logger()

# 預設技能分數（當用戶無任何報告時回傳，對應 Flutter 硬編碼值）
DEFAULT_SKILLS = SkillScores(
    emotional_value=0.83,
    listening=0.72,
    frame_control=0.67,
    escalation=0.55,
    empathy=0.60,
    humor=0.78,
)


class InsightsService:
    """成長洞察服務

    提供雷達圖技能分數查詢與約會報告列表功能。
    技能分數從最新一筆約會報告的 skills 欄位取得。
    """

    def __init__(self, session_factory: async_sessionmaker):
        self._sf = session_factory  # SQLAlchemy async session 工廠

    async def ensure_seed_data(self, user_id: str):
        """確保預設用戶有 seed 數據（首次啟動時自動建立）"""
        async with self._sf() as session:
            stmt = select(ReportRow).where(ReportRow.user_id == user_id).limit(1)
            result = await session.execute(stmt)
            if result.scalar_one_or_none():
                return  # 已有數據，跳過

            # 建立預設約會報告
            row = ReportRow(
                id=generate_cuid(),
                user_id=user_id,
                score=85,
                skills=asdict(DEFAULT_SKILLS),
                good_points=["保持了良好的眼神交流", "有效運用了回呼幽默"],
                to_improve=["在對方說話時打斷了 3 次"],
                action_items=["練習主動傾聽技巧"],
            )
            session.add(row)
            await session.commit()

    async def get_latest_skills(self, user_id: str, request_id: str) -> SkillScores:
        """取得用戶最新的 6 維技能分數

        從最新一筆約會報告的 skills 欄位取得。
        若無報告則回傳預設值。
        """
        log = logger.bind(request_id=request_id, feature="insights")
        async with self._sf() as session:
            # 取最新一筆報告的 skills
            stmt = (
                select(ReportRow.skills)
                .where(ReportRow.user_id == user_id)
                .order_by(ReportRow.created_at.desc())
                .limit(1)
            )
            result = await session.execute(stmt)
            skills_json = result.scalar_one_or_none()

        if skills_json and isinstance(skills_json, dict):
            log.info("get_latest_skills", user_id=user_id, source="db")
            return SkillScores(
                emotional_value=skills_json.get("emotional_value", 0),
                listening=skills_json.get("listening", 0),
                frame_control=skills_json.get("frame_control", 0),
                escalation=skills_json.get("escalation", 0),
                empathy=skills_json.get("empathy", 0),
                humor=skills_json.get("humor", 0),
            )

        log.info("get_latest_skills", user_id=user_id, source="default")
        return DEFAULT_SKILLS

    async def list_reports(self, user_id: str, request_id: str) -> list[DateReport]:
        """列出用戶所有約會報告，按建立時間倒序"""
        log = logger.bind(request_id=request_id, feature="insights")
        async with self._sf() as session:
            stmt = (
                select(ReportRow)
                .where(ReportRow.user_id == user_id)
                .order_by(ReportRow.created_at.desc())
            )
            result = await session.execute(stmt)
            rows = result.scalars().all()

        reports = []
        for r in rows:
            skills_data = r.skills or {}
            reports.append(DateReport(
                report_id=r.id,
                user_id=r.user_id,
                score=r.score,
                skills=SkillScores(
                    emotional_value=skills_data.get("emotional_value", 0),
                    listening=skills_data.get("listening", 0),
                    frame_control=skills_data.get("frame_control", 0),
                    escalation=skills_data.get("escalation", 0),
                    empathy=skills_data.get("empathy", 0),
                    humor=skills_data.get("humor", 0),
                ),
                good_points=r.good_points or [],
                to_improve=r.to_improve or [],
                action_items=r.action_items or [],
                created_at=r.created_at.isoformat() if r.created_at else "",
            ))
        log.info("list_reports", user_id=user_id, count=len(reports))
        return reports

    async def list_voice_coach_logs(
        self, user_id: str, request_id: str
    ) -> list[VoiceCoachLog]:
        """列出用戶所有語音教練對話紀錄，按建立時間倒序

        從 analysis_logs 表中篩選 feature='voice_coach' 的紀錄。
        """
        log = logger.bind(request_id=request_id, feature="insights")
        async with self._sf() as session:
            stmt = (
                select(AnalysisLog)
                .where(
                    AnalysisLog.user_id == user_id,
                    AnalysisLog.feature == "voice_coach",
                )
                .order_by(AnalysisLog.created_at.desc())
                .limit(50)
            )
            result = await session.execute(stmt)
            rows = result.scalars().all()

        logs = []
        for r in rows:
            output = r.output_json or {}
            logs.append(VoiceCoachLog(
                log_id=r.id,
                session_id=r.session_id or "",
                input_transcripts=output.get("input_transcripts", []),
                coach_transcripts=output.get("coach_transcripts", []),
                coaching_updates=output.get("coaching_updates", []),
                duration_ms=r.latency_ms or 0,
                created_at=r.created_at.isoformat() if r.created_at else "",
            ))
        log.info("list_voice_coach_logs", user_id=user_id, count=len(logs))
        return logs

    async def delete_voice_coach_log(
        self, user_id: str, log_id: str, request_id: str
    ) -> bool:
        """刪除指定語音教練對話紀錄，回傳是否成功刪除"""
        log = logger.bind(request_id=request_id, feature="insights")
        async with self._sf() as session:
            stmt = (
                delete(AnalysisLog)
                .where(
                    AnalysisLog.id == log_id,
                    AnalysisLog.user_id == user_id,
                    AnalysisLog.feature == "voice_coach",
                )
            )
            result = await session.execute(stmt)
            await session.commit()
            deleted = result.rowcount > 0
        log.info("delete_voice_coach_log", log_id=log_id, deleted=deleted)
        return deleted
