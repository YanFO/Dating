"""Love Coach 聊天服務

透過 Gemini 串流回應提供即時互動式兩性諮詢。
支援對話持久化（PostgreSQL）、歷史記錄管理與串流聊天。

架構遵循：
- 薄路由、厚服務原則（業務邏輯全部在此）
- 依賴注入（LLM 客戶端、功能開關、DB session factory）
- 所有外部呼叫皆有超時保護
"""

import asyncio
import structlog
from typing import AsyncGenerator, Optional

from sqlalchemy import select, func, delete

from config.constants import LLM_CHAT_STREAM_TOTAL_TIMEOUT
from infra.database.models import LoveCoachConversation, LoveCoachMessage
from modules.love_coach.errors import InvalidMessageError, ConversationNotFoundError
from modules.love_coach.models import (
    ConversationSummary,
    LoveCoachChatRequest,
    MessageWithTimestamp,
)
from modules.love_coach.prompts import LOVE_COACH_SYSTEM_PROMPT
from services.id_service import generate_cuid
from utils.time import format_iso, utcnow

logger = structlog.get_logger()

# ─── 常數 ─────────────────────────────────────────

# 送入 LLM 的最大歷史訊息數（避免超出 token 上限）
MAX_HISTORY_TURNS = 20

# 對話標題的最大長度（從首則訊息擷取）
TITLE_MAX_LENGTH = 50


class LoveCoachService:
    """Love Coach 聊天服務，提供串流聊天與對話管理功能。

    依賴注入：
    - llm_client: Gemini 客戶端（需支援 generate_chat_stream 方法）
    - feature_flags: 功能開關設定
    - session_factory: PostgreSQL async session factory
    """

    def __init__(self, llm_client, feature_flags, session_factory):
        """初始化服務，注入外部依賴"""
        self._llm = llm_client
        self._flags = feature_flags
        self._sf = session_factory

    # ─── 串流聊天（核心功能）────────────────────────

    async def chat_stream(
        self, request: LoveCoachChatRequest, request_id: str, user_id: str = "anonymous"
    ) -> tuple[str, AsyncGenerator[str, None]]:
        """串流聊天回覆，回傳 (conversation_id, text_chunk_generator)。

        流程：
        1. 載入或建立對話
        2. 儲存使用者訊息至 DB
        3. 從 DB 載入近期歷史（最多 MAX_HISTORY_TURNS 則）
        4. 呼叫 LLM 串流生成，邊產出邊收集完整回覆
        5. 串流結束後儲存模型回覆至 DB

        Args:
            request: 聊天請求（含訊息、對話 ID、語言）
            request_id: 請求追蹤 ID

        Returns:
            tuple: (conversation_id, async_generator_of_text_chunks)

        Raises:
            InvalidMessageError: 訊息為空時拋出
        """
        log = logger.bind(request_id=request_id, feature="love_coach")

        # 驗證訊息內容
        if not request.message.strip():
            raise InvalidMessageError("訊息不可為空")

        # 載入或建立對話
        conversation_id = await self._ensure_conversation(
            request.conversation_id, request.message, request_id, user_id=user_id
        )

        # 儲存使用者訊息
        await self._save_message(conversation_id, "user", request.message)

        # 從 DB 載入歷史訊息
        history = await self._load_history(conversation_id)
        log.info(
            "love_coach_stream_start",
            conversation_id=conversation_id,
            history_len=len(history),
        )

        # 建立串流生成器（含整體超時保護）
        async def _generate() -> AsyncGenerator[str, None]:
            full_response = ""
            deadline = asyncio.get_event_loop().time() + LLM_CHAT_STREAM_TOTAL_TIMEOUT
            try:
                async for chunk in self._llm.generate_chat_stream(
                    system_prompt=LOVE_COACH_SYSTEM_PROMPT,
                    messages=history,
                    request_id=request_id,
                ):
                    # 服務層整體超時檢查
                    if asyncio.get_event_loop().time() > deadline:
                        log.warning(
                            "love_coach_stream_timeout",
                            conversation_id=conversation_id,
                            request_id=request_id,
                        )
                        break
                    full_response += chunk
                    yield chunk
            finally:
                # 串流結束（無論成功或失敗），若有回覆內容則儲存
                if full_response.strip():
                    try:
                        await self._save_message(
                            conversation_id, "model", full_response
                        )
                        log.info("love_coach_stream_done", conversation_id=conversation_id)
                    except Exception as e:
                        log.warning("love_coach_save_response_failed", error=str(e))

        return conversation_id, _generate()

    # ─── 對話管理 ──────────────────────────────────

    async def get_conversations(self, user_id: str) -> list[ConversationSummary]:
        """取得使用者的所有對話摘要列表，按更新時間降序排列。

        Args:
            user_id: 使用者 ID

        Returns:
            list: 對話摘要列表
        """
        async with self._sf() as session:
            # 子查詢：計算每個對話的訊息數
            msg_count_subq = (
                select(
                    LoveCoachMessage.conversation_id,
                    func.count(LoveCoachMessage.id).label("msg_count"),
                )
                .group_by(LoveCoachMessage.conversation_id)
                .subquery()
            )

            # 主查詢：取得對話列表與訊息數
            stmt = (
                select(
                    LoveCoachConversation,
                    func.coalesce(msg_count_subq.c.msg_count, 0).label("msg_count"),
                )
                .outerjoin(
                    msg_count_subq,
                    LoveCoachConversation.id == msg_count_subq.c.conversation_id,
                )
                .where(
                    LoveCoachConversation.user_id == user_id,
                    LoveCoachConversation.status == "active",
                )
                .order_by(LoveCoachConversation.updated_at.desc())
            )

            result = await session.execute(stmt)
            rows = result.all()

            return [
                ConversationSummary(
                    id=row[0].id,
                    title=row[0].title,
                    message_count=row[1],
                    created_at=format_iso(row[0].created_at),
                    updated_at=format_iso(row[0].updated_at),
                )
                for row in rows
            ]

    async def get_conversation_messages(
        self, conversation_id: str, user_id: str
    ) -> list[MessageWithTimestamp]:
        """取得指定對話的所有訊息，按時間順序排列。

        Args:
            conversation_id: 對話 ID
            user_id: 使用者 ID（用於授權檢查）

        Returns:
            list: 帶時間戳的訊息列表

        Raises:
            ConversationNotFoundError: 對話不存在或不屬於該用戶時拋出
        """
        async with self._sf() as session:
            # 確認對話存在且屬於該用戶
            conv = await session.get(LoveCoachConversation, conversation_id)
            if not conv or conv.user_id != user_id:
                raise ConversationNotFoundError(
                    f"對話 {conversation_id} 不存在"
                )

            # 取得所有訊息
            stmt = (
                select(LoveCoachMessage)
                .where(LoveCoachMessage.conversation_id == conversation_id)
                .order_by(LoveCoachMessage.created_at.asc())
            )
            result = await session.execute(stmt)
            messages = result.scalars().all()

            return [
                MessageWithTimestamp(
                    id=msg.id,
                    role=msg.role,
                    text=msg.text,
                    created_at=format_iso(msg.created_at),
                )
                for msg in messages
            ]

    async def delete_conversation(self, conversation_id: str, user_id: str) -> None:
        """刪除指定對話及其所有訊息。

        Args:
            conversation_id: 對話 ID
            user_id: 使用者 ID（用於授權檢查）

        Raises:
            ConversationNotFoundError: 對話不存在或不屬於該用戶時拋出
        """
        async with self._sf() as session:
            conv = await session.get(LoveCoachConversation, conversation_id)
            if not conv or conv.user_id != user_id:
                raise ConversationNotFoundError(
                    f"對話 {conversation_id} 不存在"
                )

            # 先刪訊息，再刪對話
            await session.execute(
                delete(LoveCoachMessage).where(
                    LoveCoachMessage.conversation_id == conversation_id
                )
            )
            await session.delete(conv)
            await session.commit()

            logger.info("love_coach_conversation_deleted", conversation_id=conversation_id)

    # ─── 內部方法 ──────────────────────────────────

    async def _ensure_conversation(
        self, conversation_id: Optional[str], first_message: str, request_id: str,
        user_id: str = "anonymous",
    ) -> str:
        """確保對話存在：如有 ID 則載入，否則新建。

        新建對話時，從首則訊息擷取前 N 字作為標題。

        Args:
            conversation_id: 可選的既有對話 ID
            first_message: 當前使用者訊息（用於生成標題）
            request_id: 請求追蹤 ID
            user_id: 使用者 ID

        Returns:
            str: 對話 ID
        """
        async with self._sf() as session:
            if conversation_id:
                # 嘗試載入既有對話
                conv = await session.get(LoveCoachConversation, conversation_id)
                if conv:
                    return conv.id
                # ID 無效，記錄警告後新建
                logger.warning(
                    "love_coach_conversation_not_found",
                    conversation_id=conversation_id,
                    request_id=request_id,
                )

            # 新建對話
            new_id = generate_cuid()
            title = first_message[:TITLE_MAX_LENGTH].strip()
            if len(first_message) > TITLE_MAX_LENGTH:
                title += "…"

            conv = LoveCoachConversation(
                id=new_id,
                user_id=user_id,
                title=title,
                status="active",
            )
            session.add(conv)
            await session.commit()

            logger.info(
                "love_coach_conversation_created",
                conversation_id=new_id,
                request_id=request_id,
            )
            return new_id

    async def _save_message(
        self, conversation_id: str, role: str, text: str
    ) -> None:
        """儲存一則訊息至資料庫。

        同時更新對話的 updated_at 時間戳。

        Args:
            conversation_id: 對話 ID
            role: 角色（user / model）
            text: 訊息內容
        """
        async with self._sf() as session:
            msg = LoveCoachMessage(
                id=generate_cuid(),
                conversation_id=conversation_id,
                role=role,
                text=text,
            )
            session.add(msg)

            # 更新對話的 updated_at
            conv = await session.get(LoveCoachConversation, conversation_id)
            if conv:
                conv.updated_at = utcnow()

            await session.commit()

    async def _load_history(self, conversation_id: str) -> list[dict]:
        """從 DB 載入對話歷史，轉換為 LLM 所需格式。

        使用 SQL LIMIT 只從 DB 載入最近 MAX_HISTORY_TURNS 則訊息，
        避免大量訊息全部載入記憶體。結果反轉為時間正序。

        Args:
            conversation_id: 對話 ID

        Returns:
            list: [{"role": "user"|"model", "text": str}, ...]
        """
        async with self._sf() as session:
            # 先按時間倒序取最近 N 則，再反轉為正序
            stmt = (
                select(LoveCoachMessage)
                .where(LoveCoachMessage.conversation_id == conversation_id)
                .order_by(LoveCoachMessage.created_at.desc())
                .limit(MAX_HISTORY_TURNS)
            )
            result = await session.execute(stmt)
            recent_desc = result.scalars().all()

            # 反轉為時間正序（LLM 需要從舊到新）
            recent = list(reversed(recent_desc))

            return [
                {"role": msg.role, "text": msg.text}
                for msg in recent
            ]
