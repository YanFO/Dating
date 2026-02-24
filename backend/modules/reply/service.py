"""回覆教練模組的核心服務，負責聊天分析與回覆建議生成。

分析結果寫入 analysis_logs 表以供後續 Insights 使用。
"""

import time

import structlog
from sqlalchemy.ext.asyncio import async_sessionmaker

from infra.database.models import AnalysisLog as LogRow
from modules.reply.errors import NoInputProvided
from modules.reply.models import (
    CoachPanel,
    EmotionAnalysis,
    ReplyOption,
    ReplyRequest,
    ReplyResponse,
    StageCoaching,
)
from modules.reply.prompts import build_memory_context, build_reply_system_prompt
from services.id_service import generate_cuid

logger = structlog.get_logger()

MOCK_REPLY_RESPONSE = ReplyResponse(
    emotion_analysis=EmotionAnalysis(
        detected_emotion="略帶敷衍但仍有興趣",
        subtext="對方回覆雖短，但使用了表情符號且回覆速度正常，表示仍有基本興趣，但需要更有趣的話題來提升互動品質。",
        confidence=0.78,
    ),
    reply_options=[
        ReplyOption(
            text="哈哈真的～對了你週末都在幹嘛？",
            intent="話題延伸",
            strategy="輕鬆接話 + 開放式提問維持對話",
            framework_technique="無",
        ),
        ReplyOption(
            text="感覺你應該是週末到處吃美食的人吧？😏",
            intent="引發好奇",
            strategy="用冷讀術猜測對方興趣，展現觀察力，讓對方想回應。",
            framework_technique="冷讀假設",
        ),
        ReplyOption(
            text="外表高冷但其實很有趣齁 😏 有反差的人比較吸引我",
            intent="建立共鳴",
            strategy="先拉（有反差很有趣），用篩選者姿態暗示你在評估對方。",
            framework_technique="自然自我揭露",
        ),
    ],
    coach_panel=CoachPanel(
        perspective_note="對方目前的回覆屬於「低投資回覆」，這是正常的初期互動模式。關鍵是不要急著追問或連發訊息，而是用有趣的話題吸引對方主動投入更多。",
        dos=[
            "用幽默感帶動對話節奏",
            "分享有趣的個人經歷來引起好奇心",
            "保持回覆間隔與對方相近",
        ],
        donts=[
            "不要連續發送多條訊息",
            "不要問「你在幹嘛」這種低價值問題",
            "不要過度使用表情符號或貼圖",
        ],
    ),
    stage_coaching=StageCoaching(
        current_stage="early",
        stage_strategy="此階段重點在建立好感與好奇心，避免面試式問答，運用自我揭露與話題留白引導對方主動投入。",
        technique_used="話題留白 + 適當自我揭露",
        stage_warnings=[
            "不要連續發送多條訊息",
            "太快聊太深會讓人想逃",
            "避免急著聊私密話題",
        ],
    ),
)

class ReplyService:
    """回覆教練服務，透過 LLM 分析聊天內容並產生回覆建議。"""

    def __init__(self, llm_client, feature_flags, session_factory: async_sessionmaker, fallback_client=None, match_service=None):
        """初始化回覆服務，設定 LLM 客戶端、DB session 與功能旗標。"""
        self._llm = llm_client
        self._fallback = fallback_client
        self._flags = feature_flags
        self._sf = session_factory  # SQLAlchemy async session 工廠
        self._match_service = match_service  # 用於查詢/更新 match memory

    async def _write_log(
        self, request: ReplyRequest, result_dict: dict | None,
        latency_ms: int, request_id: str, user_id: str = "anonymous",
        status: str = "success", error_msg: str | None = None,
    ):
        """將分析請求/回應寫入 analysis_logs 表"""
        input_type = "screenshot" if request.screenshot_base64 else "text"
        input_summary = request.chat_text or "(screenshot only)"
        try:
            async with self._sf() as session:
                row = LogRow(
                    id=generate_cuid(),
                    user_id=user_id,
                    feature="reply",
                    input_type=input_type,
                    input_summary=input_summary[:500],
                    output_json=result_dict,
                    llm_model=getattr(self._llm, "_model", None),
                    latency_ms=latency_ms,
                    status=status,
                    error_message=error_msg,
                )
                session.add(row)
                await session.commit()
        except Exception as e:
            # 日誌寫入失敗不影響主流程
            logger.warning("analysis_log_write_failed", error=str(e), request_id=request_id)

    async def _call_llm(self, client, request, system_prompt, user_prompt, request_id):
        """呼叫 LLM 進行截圖或文字分析，回傳原始結果。"""
        if request.screenshot_base64:
            return await client.analyze_image(
                image_base64=request.screenshot_base64,
                system_prompt=system_prompt,
                user_prompt=user_prompt,
                request_id=request_id,
            )
        return await client.analyze_text(
            system_prompt=system_prompt,
            user_prompt=user_prompt,
            request_id=request_id,
        )

    async def analyze(
        self, request: ReplyRequest, request_id: str, user_id: str = "anonymous"
    ) -> ReplyResponse:
        """執行回覆分析，回傳情緒分析與回覆建議。若帶 match_id 則注入記憶並自動擷取。"""
        log = logger.bind(request_id=request_id, feature="reply", user_id=user_id)

        if self._flags.ENABLE_MOCK_MODE:
            log.info("returning_mock_response")
            return MOCK_REPLY_RESPONSE

        if not request.chat_text and not request.screenshot_base64:
            raise NoInputProvided("At least chat_text or screenshot is required")

        system_prompt = build_reply_system_prompt(
            request.relationship_stage,
            request.user_gender,
            request.target_gender,
        )

        # 若有 match_id，查詢記憶並注入 system prompt
        if request.match_id and self._match_service:
            try:
                memory_data = await self._match_service.get_memory_for_prompt(
                    request.match_id, request_id,
                )
                memory_context = build_memory_context(memory_data)
                if memory_context:
                    system_prompt += memory_context
                    log.info("memory_injected", match_id=request.match_id)
            except Exception as e:
                log.warning("memory_injection_failed", error=str(e), match_id=request.match_id)

        user_prompt = self._build_user_prompt(request)
        log.info(
            "calling_llm",
            has_screenshot=bool(request.screenshot_base64),
            relationship_stage=request.relationship_stage,
            match_id=request.match_id,
        )

        # 計時 LLM 呼叫
        t0 = time.monotonic()
        try:
            raw = await self._call_llm(self._llm, request, system_prompt, user_prompt, request_id)
            latency_ms = int((time.monotonic() - t0) * 1000)
            result = self._parse_response(raw)
            # 寫入分析日誌（成功）
            await self._write_log(request, raw, latency_ms, request_id, user_id=user_id)

            # 若有 match_id 且 LLM 回傳 memory_extraction，自動 merge 到 DB
            if request.match_id and self._match_service and result.memory_extraction:
                try:
                    await self._match_service.merge_extracted_memories(
                        user_id, request.match_id, result.memory_extraction, request_id,
                    )
                    log.info("memory_extracted_and_merged", match_id=request.match_id)
                except Exception as e:
                    log.warning("memory_merge_failed", error=str(e), match_id=request.match_id)

            return result
        except Exception as e:
            latency_ms = int((time.monotonic() - t0) * 1000)
            # 寫入錯誤日誌
            await self._write_log(request, None, latency_ms, request_id, user_id=user_id, status="error", error_msg=str(e))
            raise

    def _build_user_prompt(self, request: ReplyRequest) -> str:
        """根據請求內容組合使用者提示詞。"""
        parts = []
        if request.chat_text:
            parts.append(f"聊天記錄：\n{request.chat_text}")
        if request.screenshot_base64:
            parts.append("請分析附帶的聊天截圖。")
        parts.append(f"請用{request.language}回覆。")
        return "\n".join(parts)

    def _parse_response(self, raw: dict) -> ReplyResponse:
        """將 LLM 原始回應解析為結構化的回覆回應物件。"""
        ea_raw = raw.get("emotion_analysis", {})
        emotion_analysis = EmotionAnalysis(
            detected_emotion=ea_raw.get("detected_emotion", ""),
            subtext=ea_raw.get("subtext", ""),
            confidence=float(ea_raw.get("confidence", 0.5)),
        )
        reply_options = [
            ReplyOption(
                text=opt.get("text", ""),
                intent=opt.get("intent", "unknown"),
                strategy=opt.get("strategy", ""),
                framework_technique=opt.get("framework_technique", ""),
            )
            for opt in raw.get("reply_options", [])
        ]
        cp_raw = raw.get("coach_panel", {})
        coach_panel = CoachPanel(
            perspective_note=cp_raw.get("perspective_note", ""),
            dos=cp_raw.get("dos", []),
            donts=cp_raw.get("donts", []),
        )
        sc_raw = raw.get("stage_coaching", {})
        stage_coaching = StageCoaching(
            current_stage=sc_raw.get("current_stage", "early"),
            stage_strategy=sc_raw.get("stage_strategy", ""),
            technique_used=sc_raw.get("technique_used", ""),
            stage_warnings=sc_raw.get("stage_warnings", []),
        ) if sc_raw else None
        memory_extraction = raw.get("memory_extraction")
        return ReplyResponse(
            emotion_analysis=emotion_analysis,
            reply_options=reply_options,
            coach_panel=coach_panel,
            stage_coaching=stage_coaching,
            memory_extraction=memory_extraction,
        )
