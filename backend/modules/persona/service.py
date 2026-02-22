"""Persona 業務邏輯服務

管理用戶的數位人格設定（語調滑桿）與沙盒改寫功能。
語調設定持久化至 PostgreSQL user_personas 表。
沙盒改寫透過 LLM 根據語調設定動態改寫訊息。
"""

import structlog
from sqlalchemy import select
from sqlalchemy.ext.asyncio import async_sessionmaker

from infra.database.models import UserPersona as PersonaRow
from modules.persona.models import PersonaSettings, SandboxResult
from modules.persona.prompts import build_sandbox_prompt
from services.id_service import generate_cuid

logger = structlog.get_logger()

# Mock 沙盒回應（當啟用 mock mode 時使用）
MOCK_SANDBOX_REWRITE = "Ay 今晚吃啥？有點餓了 ngl 🍕"


class PersonaService:
    """數位人格服務

    提供語調設定的讀取/更新，以及沙盒訊息改寫功能。
    語調設定持久化至 PostgreSQL，沙盒改寫呼叫 LLM。
    """

    def __init__(self, llm_client, feature_flags, session_factory: async_sessionmaker, fallback_client=None):
        self._llm = llm_client            # 主要 LLM 客戶端（Gemini）
        self._fallback = fallback_client   # 備用 LLM 客戶端（OpenAI）
        self._flags = feature_flags
        self._sf = session_factory         # SQLAlchemy async session 工廠

    async def _get_or_create_row(self, session, user_id: str) -> PersonaRow:
        """取得用戶的人格設定 ORM 行，若不存在則建立預設值"""
        stmt = select(PersonaRow).where(PersonaRow.user_id == user_id)
        result = await session.execute(stmt)
        row = result.scalar_one_or_none()
        if not row:
            row = PersonaRow(id=generate_cuid(), user_id=user_id)
            session.add(row)
            await session.flush()
        return row

    def _row_to_model(self, row: PersonaRow) -> PersonaSettings:
        """將 ORM 行轉換為領域模型"""
        return PersonaSettings(
            user_id=row.user_id,
            sync_pct=row.sync_pct,
            emoji_usage=row.emoji_usage,
            sentence_length=row.sentence_length,
            colloquialism=row.colloquialism,
        )

    async def get_persona(self, user_id: str, request_id: str) -> PersonaSettings:
        """取得用戶人格設定（若不存在則建立預設值）"""
        log = logger.bind(request_id=request_id, feature="persona")
        async with self._sf() as session:
            row = await self._get_or_create_row(session, user_id)
            await session.commit()
        log.info("get_persona", user_id=user_id)
        return self._row_to_model(row)

    async def update_tone(
        self,
        user_id: str,
        emoji_usage: float,
        sentence_length: float,
        colloquialism: float,
        request_id: str,
    ) -> PersonaSettings:
        """更新用戶三個語調滑桿的值並持久化"""
        log = logger.bind(request_id=request_id, feature="persona")
        async with self._sf() as session:
            row = await self._get_or_create_row(session, user_id)
            row.emoji_usage = emoji_usage
            row.sentence_length = sentence_length
            row.colloquialism = colloquialism
            await session.commit()
            await session.refresh(row)
        log.info("tone_updated", emoji_usage=emoji_usage)
        return self._row_to_model(row)

    async def sandbox_rewrite(
        self, user_id: str, text: str, request_id: str
    ) -> SandboxResult:
        """使用 LLM 根據用戶語調設定改寫訊息"""
        log = logger.bind(request_id=request_id, feature="persona")

        # Mock mode 直接回傳預設結果
        if self._flags.ENABLE_MOCK_MODE:
            log.info("returning_mock_sandbox")
            return SandboxResult(original=text, rewritten=MOCK_SANDBOX_REWRITE)

        # 從 DB 讀取語調設定
        async with self._sf() as session:
            row = await self._get_or_create_row(session, user_id)
            await session.commit()

        # 根據語調設定動態組建 prompt
        system_prompt = build_sandbox_prompt(
            emoji_usage=row.emoji_usage,
            sentence_length=row.sentence_length,
            colloquialism=row.colloquialism,
        )
        user_prompt = f"請改寫這則訊息：{text}"

        log.info("calling_llm_for_sandbox")

        try:
            raw = await self._llm.analyze_text(
                system_prompt=system_prompt,
                user_prompt=user_prompt,
                request_id=request_id,
            )
            rewritten = self._extract_text(raw)
        except Exception as e:
            log.warning("primary_llm_failed", error=str(e))
            if self._fallback:
                raw = await self._fallback.analyze_text(
                    system_prompt=system_prompt,
                    user_prompt=user_prompt,
                    request_id=request_id,
                )
                rewritten = self._extract_text(raw)
            else:
                raise

        return SandboxResult(original=text, rewritten=rewritten)

    @staticmethod
    def _extract_text(raw) -> str:
        """從 LLM 回應中提取改寫文字

        LLM 可能回傳 dict（JSON 模式）或字串，需統一處理。
        """
        if isinstance(raw, str):
            return raw
        if isinstance(raw, dict):
            for key in ("rewritten_text", "rewritten", "text", "message", "content"):
                if key in raw and isinstance(raw[key], str):
                    return raw[key]
            for v in raw.values():
                if isinstance(v, str):
                    return v
        return str(raw)
