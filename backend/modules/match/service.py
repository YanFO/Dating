"""Match 業務邏輯服務

管理用戶的約會管線（Active Pipeline）與每個對象的記憶檔案。
使用 PostgreSQL 持久化，透過 SQLAlchemy async session 操作。
"""

import structlog
from sqlalchemy import select
from sqlalchemy.ext.asyncio import async_sessionmaker

from infra.database.models import Match as MatchRow, MatchMemory as MemoryRow
from modules.match.errors import MatchNotFound, MemoryNotFound
from modules.match.models import (
    ChatImportResult,
    MatchRecord,
    MemoryProfile,
    MEMORY_LIST_FIELDS,
    MEMORY_STRING_FIELDS,
)
from modules.match.prompts import CHAT_IMPORT_SYSTEM_PROMPT, CHAT_IMPORT_MULTI_SYSTEM_PROMPT
from services.id_service import generate_cuid

logger = structlog.get_logger()


class MatchService:
    """Match 管線服務

    提供約會對象的 CRUD 與記憶檔案管理功能。
    所有操作均持久化至 PostgreSQL matches / match_memories 表。
    """

    def __init__(self, session_factory: async_sessionmaker, llm_client=None, fallback_client=None):
        # SQLAlchemy async session 工廠
        self._sf = session_factory
        self._llm = llm_client
        self._fallback = fallback_client

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

            # 同時刪除關聯的 memory
            mem_stmt = select(MemoryRow).where(MemoryRow.match_id == match_id)
            mem_result = await session.execute(mem_stmt)
            mem_row = mem_result.scalar_one_or_none()
            if mem_row:
                await session.delete(mem_row)

            await session.delete(row)
            await session.commit()
        log.info("match_deleted", match_id=match_id)

    # ─── Memory CRUD ──────────────────────────────────

    def _memory_row_to_model(self, row: MemoryRow) -> MemoryProfile:
        """將 Memory ORM 行轉換為領域模型"""
        return MemoryProfile(
            memory_id=row.id,
            user_id=row.user_id,
            match_id=row.match_id,
            birthday=row.birthday,
            anniversaries=row.anniversaries or [],
            mbti_or_zodiac=row.mbti_or_zodiac,
            routine=row.routine or [],
            favorite_food=row.favorite_food or [],
            favorite_restaurant=row.favorite_restaurant or [],
            disliked_food=row.disliked_food or [],
            dietary_restrictions=row.dietary_restrictions or [],
            beverage_customization=row.beverage_customization or [],
            favorite_places=row.favorite_places or [],
            travel_wishlist=row.travel_wishlist or [],
            hobbies=row.hobbies or [],
            entertainment_tastes=row.entertainment_tastes or [],
            landmines=row.landmines or [],
            pet_peeves=row.pet_peeves or [],
            soothing_methods=row.soothing_methods or [],
            love_languages=row.love_languages or [],
            wishlist=row.wishlist or [],
            favorite_brands=row.favorite_brands or [],
            aesthetic_preference=row.aesthetic_preference or [],
            other_notes=row.other_notes or [],
            created_at=row.created_at.isoformat() if row.created_at else "",
            updated_at=row.updated_at.isoformat() if row.updated_at else "",
        )

    async def _verify_match_ownership(self, session, user_id: str, match_id: str) -> None:
        """驗證 match 是否屬於該用戶"""
        stmt = select(MatchRow).where(MatchRow.id == match_id, MatchRow.user_id == user_id)
        result = await session.execute(stmt)
        if not result.scalar_one_or_none():
            raise MatchNotFound(f"Match {match_id} not found")

    async def get_memory(self, user_id: str, match_id: str, request_id: str) -> MemoryProfile:
        """取得 match 的 memory profile（不存在則回傳空 profile）"""
        log = logger.bind(request_id=request_id, feature="match_memory")
        async with self._sf() as session:
            await self._verify_match_ownership(session, user_id, match_id)
            stmt = select(MemoryRow).where(MemoryRow.match_id == match_id)
            result = await session.execute(stmt)
            row = result.scalar_one_or_none()
        if row:
            log.info("get_memory", match_id=match_id, found=True)
            return self._memory_row_to_model(row)
        log.info("get_memory", match_id=match_id, found=False)
        return MemoryProfile(memory_id="", user_id=user_id, match_id=match_id)

    async def upsert_memory(
        self, user_id: str, match_id: str, data: dict, request_id: str,
    ) -> MemoryProfile:
        """建立或更新 memory profile（部分更新，只覆蓋有傳入的欄位）"""
        log = logger.bind(request_id=request_id, feature="match_memory")
        async with self._sf() as session:
            await self._verify_match_ownership(session, user_id, match_id)
            stmt = select(MemoryRow).where(MemoryRow.match_id == match_id)
            result = await session.execute(stmt)
            row = result.scalar_one_or_none()

            if not row:
                row = MemoryRow(id=generate_cuid(), user_id=user_id, match_id=match_id)
                session.add(row)

            # 更新有傳入的欄位
            for field_name in MEMORY_STRING_FIELDS:
                if field_name in data and data[field_name] is not None:
                    setattr(row, field_name, data[field_name])
            for field_name in MEMORY_LIST_FIELDS:
                if field_name in data and data[field_name] is not None:
                    setattr(row, field_name, data[field_name])

            await session.commit()
            await session.refresh(row)
        log.info("upsert_memory", match_id=match_id)
        return self._memory_row_to_model(row)

    async def delete_memory(self, user_id: str, match_id: str, request_id: str) -> None:
        """刪除 match 的 memory profile"""
        log = logger.bind(request_id=request_id, feature="match_memory")
        async with self._sf() as session:
            await self._verify_match_ownership(session, user_id, match_id)
            stmt = select(MemoryRow).where(MemoryRow.match_id == match_id)
            result = await session.execute(stmt)
            row = result.scalar_one_or_none()
            if not row:
                raise MemoryNotFound(f"Memory for match {match_id} not found")
            await session.delete(row)
            await session.commit()
        log.info("delete_memory", match_id=match_id)

    async def get_memory_for_prompt(self, match_id: str, request_id: str) -> dict:
        """取得 memory profile 的 dict 格式（給 AI prompt 組裝用）"""
        log = logger.bind(request_id=request_id, feature="match_memory")
        async with self._sf() as session:
            stmt = select(MemoryRow).where(MemoryRow.match_id == match_id)
            result = await session.execute(stmt)
            row = result.scalar_one_or_none()
        if not row:
            log.info("get_memory_for_prompt", match_id=match_id, found=False)
            return {}
        log.info("get_memory_for_prompt", match_id=match_id, found=True)
        return {
            "birthday": row.birthday,
            "mbti_or_zodiac": row.mbti_or_zodiac,
            "anniversaries": row.anniversaries or [],
            "routine": row.routine or [],
            "favorite_food": row.favorite_food or [],
            "favorite_restaurant": row.favorite_restaurant or [],
            "disliked_food": row.disliked_food or [],
            "dietary_restrictions": row.dietary_restrictions or [],
            "beverage_customization": row.beverage_customization or [],
            "favorite_places": row.favorite_places or [],
            "travel_wishlist": row.travel_wishlist or [],
            "hobbies": row.hobbies or [],
            "entertainment_tastes": row.entertainment_tastes or [],
            "landmines": row.landmines or [],
            "pet_peeves": row.pet_peeves or [],
            "soothing_methods": row.soothing_methods or [],
            "love_languages": row.love_languages or [],
            "wishlist": row.wishlist or [],
            "favorite_brands": row.favorite_brands or [],
            "aesthetic_preference": row.aesthetic_preference or [],
            "other_notes": row.other_notes or [],
        }

    async def merge_extracted_memories(
        self, user_id: str, match_id: str, extraction: dict, request_id: str,
    ) -> None:
        """將 LLM 擷取的記憶 merge 到現有 profile（append 不覆蓋，去重）"""
        log = logger.bind(request_id=request_id, feature="match_memory")
        async with self._sf() as session:
            stmt = select(MemoryRow).where(MemoryRow.match_id == match_id)
            result = await session.execute(stmt)
            row = result.scalar_one_or_none()

            if not row:
                row = MemoryRow(id=generate_cuid(), user_id=user_id, match_id=match_id)
                session.add(row)

            # 字串欄位：只在原本為空時寫入
            for field_name in MEMORY_STRING_FIELDS:
                new_val = extraction.get(field_name)
                if new_val and not getattr(row, field_name):
                    setattr(row, field_name, new_val)

            # 陣列欄位：append 去重
            for field_name in MEMORY_LIST_FIELDS:
                new_items = extraction.get(field_name, [])
                if not new_items:
                    continue
                existing = getattr(row, field_name) or []
                # 對於簡單字串陣列，用 set 去重；對於 dict 陣列（如 anniversaries），用 str 序列化去重
                existing_set = {str(item) for item in existing}
                merged = list(existing)
                for item in new_items:
                    if str(item) not in existing_set:
                        merged.append(item)
                        existing_set.add(str(item))
                setattr(row, field_name, merged)

            await session.commit()
        log.info("merge_extracted_memories", match_id=match_id)

    # ─── Chat Import (LLM 分析聊天記錄) ──────────────

    async def import_chat(
        self,
        user_id: str,
        request_id: str,
        chat_text: str | None = None,
        image_base64: str | None = None,
    ) -> ChatImportResult:
        """分析聊天記錄，自動建立 match + memory"""
        log = logger.bind(request_id=request_id, feature="match_import")

        if not self._llm:
            raise RuntimeError("LLM client not configured for match service")

        user_prompt = "請分析以下聊天記錄。"
        if chat_text:
            user_prompt = f"請分析以下聊天記錄：\n\n{chat_text}"

        # 呼叫 LLM
        try:
            if image_base64:
                raw = await self._llm.analyze_image(
                    image_base64=image_base64,
                    system_prompt=CHAT_IMPORT_SYSTEM_PROMPT,
                    user_prompt=user_prompt,
                    request_id=request_id,
                )
            else:
                raw = await self._llm.analyze_text(
                    system_prompt=CHAT_IMPORT_SYSTEM_PROMPT,
                    user_prompt=user_prompt,
                    request_id=request_id,
                )
        except Exception as e:
            log.error("llm_call_failed", error=str(e))
            if self._fallback:
                log.info("trying_fallback_client")
                if image_base64:
                    raw = await self._fallback.analyze_image(
                        image_base64=image_base64,
                        system_prompt=CHAT_IMPORT_SYSTEM_PROMPT,
                        user_prompt=user_prompt,
                        request_id=request_id,
                    )
                else:
                    raw = await self._fallback.analyze_text(
                        system_prompt=CHAT_IMPORT_SYSTEM_PROMPT,
                        user_prompt=user_prompt,
                        request_id=request_id,
                    )
            else:
                raise

        # 解析 LLM 回應
        name = raw.get("name", "未知")
        relationship_stage = raw.get("relationship_stage", "early")
        if relationship_stage not in ("early", "flirting", "couple"):
            relationship_stage = "early"
        context_tag = raw.get("context_tag", "")
        memory_extraction = raw.get("memory_extraction", {})

        log.info(
            "llm_analysis_done",
            name=name,
            stage=relationship_stage,
            context_tag=context_tag,
        )

        # 建立 match
        match_record = await self.create_match(
            user_id=user_id,
            name=name,
            context_tag=context_tag or None,
            request_id=request_id,
        )

        # 寫入 memory
        if memory_extraction:
            await self.merge_extracted_memories(
                user_id=user_id,
                match_id=match_record.match_id,
                extraction=memory_extraction,
                request_id=request_id,
            )

        # 讀回 memory
        memory = await self.get_memory(
            user_id=user_id,
            match_id=match_record.match_id,
            request_id=request_id,
        )

        return ChatImportResult(
            match=match_record,
            memory=memory,
            relationship_stage=relationship_stage,
        )

    async def import_chat_multi(
        self,
        user_id: str,
        request_id: str,
        images_base64: list[str],
        chat_text: str | None = None,
    ) -> list[ChatImportResult]:
        """分析多張聊天截圖，透過頭貼與聊天室名稱判斷不同對象，各自建立 match + memory"""
        log = logger.bind(request_id=request_id, feature="match_import_multi", image_count=len(images_base64))

        if not self._llm:
            raise RuntimeError("LLM client not configured for match service")

        user_prompt = "請分析以下多張聊天截圖，辨識不同的對象。"
        if chat_text:
            user_prompt += f"\n\n補充文字：{chat_text}"

        # 呼叫 LLM（多圖）
        try:
            raw_list = await self._llm.analyze_images(
                images_base64=images_base64,
                system_prompt=CHAT_IMPORT_MULTI_SYSTEM_PROMPT,
                user_prompt=user_prompt,
                request_id=request_id,
            )
        except Exception as e:
            log.error("llm_multi_call_failed", error=str(e))
            if self._fallback:
                log.info("trying_fallback_client")
                raw_list = await self._fallback.analyze_images(
                    images_base64=images_base64,
                    system_prompt=CHAT_IMPORT_MULTI_SYSTEM_PROMPT,
                    user_prompt=user_prompt,
                    request_id=request_id,
                )
            else:
                raise

        # 為每個辨識出的對象建立 match + memory
        results: list[ChatImportResult] = []
        for raw in raw_list:
            name = raw.get("name", "未知")
            relationship_stage = raw.get("relationship_stage", "early")
            if relationship_stage not in ("early", "flirting", "couple"):
                relationship_stage = "early"
            context_tag = raw.get("context_tag", "")
            memory_extraction = raw.get("memory_extraction", {})

            log.info("llm_multi_analysis_person", name=name, stage=relationship_stage)

            match_record = await self.create_match(
                user_id=user_id,
                name=name,
                context_tag=context_tag or None,
                request_id=request_id,
            )

            if memory_extraction:
                await self.merge_extracted_memories(
                    user_id=user_id,
                    match_id=match_record.match_id,
                    extraction=memory_extraction,
                    request_id=request_id,
                )

            memory = await self.get_memory(
                user_id=user_id,
                match_id=match_record.match_id,
                request_id=request_id,
            )

            results.append(ChatImportResult(
                match=match_record,
                memory=memory,
                relationship_stage=relationship_stage,
            ))

        log.info("import_chat_multi_done", match_count=len(results))
        return results
