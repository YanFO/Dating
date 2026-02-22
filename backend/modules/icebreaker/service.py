"""搭訕破冰模組的核心服務，負責場景分析與開場白生成。

分析結果寫入 analysis_logs 表以供後續 Insights 使用。
"""

import time

import structlog
from sqlalchemy.ext.asyncio import async_sessionmaker

from infra.database.models import AnalysisLog as LogRow
from modules.icebreaker.errors import InvalidInputError
from modules.icebreaker.models import (
    IcebreakerRequest,
    IcebreakerResponse,
    ObservationHook,
    OpeningLine,
    TopicSuggestion,
)
from modules.icebreaker.prompts import ICEBREAKER_SYSTEM_PROMPT
from services.id_service import generate_cuid

logger = structlog.get_logger()

MOCK_ICEBREAKER_RESPONSE = IcebreakerResponse(
    scene_analysis="咖啡廳場景，對方穿著休閒，正在閱讀一本書，氛圍輕鬆適合搭訕。",
    approach_readiness="黃燈(需謹慎)",
    observation_hooks=[
        ObservationHook(
            detail="對方正在閱讀一本書",
            hook_type="common_ground",
        ),
        ObservationHook(
            detail="對方點了一杯拿鐵",
            hook_type="environmental",
        ),
        ObservationHook(
            detail="穿著休閒舒適，氣質輕鬆",
            hook_type="compliment",
        ),
    ],
    opening_lines=[
        OpeningLine(
            text="嘿，那本書看起來很有趣，是什麼類型的？",
            tone="friendly_curious",
            confidence=0.92,
            based_on="對方正在閱讀一本書",
        ),
        OpeningLine(
            text="不好意思打擾，我注意到你點的也是拿鐵，這裡的拿鐵真的很讚對吧？",
            tone="casual_warm",
            confidence=0.87,
            based_on="對方點了一杯拿鐵",
        ),
        OpeningLine(
            text="你好，我一個人來這裡讀書，發現這個位置的光線最好，你也是嗎？",
            tone="observational",
            confidence=0.85,
            based_on="對方正在閱讀一本書",
        ),
    ],
    topic_suggestions=[
        TopicSuggestion(
            topic="分享自己最近看的書或影集",
            context="對方正在閱讀，用閱讀作為共同話題自然延伸",
        ),
        TopicSuggestion(
            topic="聊這家咖啡廳的特色飲品",
            context="你們都在同一家咖啡廳，可以用環境作為共同點",
        ),
    ],
    behavior_tips=[
        "保持1.2公尺以上的社交距離，不要突然靠近",
        "先微笑再開口，建立視覺友善訊號",
        "身體稍微側身站立，避免正面直對造成壓迫感",
        "如果對方戴著耳機，等待對方摘下後再搭話",
    ],
)

# 匿名用戶 ID（Phase 1 無驗證）
DEFAULT_USER_ID = "anonymous"


class IcebreakerService:
    """破冰服務，透過 LLM 分析場景並產生搭訕建議。"""

    def __init__(self, llm_client, feature_flags, session_factory: async_sessionmaker, fallback_client=None):
        """初始化破冰服務，設定 LLM 客戶端、DB session 與功能旗標。"""
        self._llm = llm_client
        self._fallback = fallback_client
        self._flags = feature_flags
        self._sf = session_factory  # SQLAlchemy async session 工廠

    async def _write_log(
        self, request: IcebreakerRequest, result_dict: dict | None,
        latency_ms: int, request_id: str, status: str = "success", error_msg: str | None = None,
    ):
        """將分析請求/回應寫入 analysis_logs 表"""
        input_type = "image" if request.image_base64 else "text"
        input_summary = request.scene_description or "(image only)"
        try:
            async with self._sf() as session:
                row = LogRow(
                    id=generate_cuid(),
                    user_id=DEFAULT_USER_ID,
                    feature="icebreaker",
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

    async def _call_llm(self, client, request, user_prompt, request_id):
        """呼叫 LLM 進行圖片或文字分析，回傳原始結果。"""
        if request.image_base64:
            return await client.analyze_image(
                image_base64=request.image_base64,
                system_prompt=ICEBREAKER_SYSTEM_PROMPT,
                user_prompt=user_prompt,
                request_id=request_id,
            )
        return await client.analyze_text(
            system_prompt=ICEBREAKER_SYSTEM_PROMPT,
            user_prompt=user_prompt,
            request_id=request_id,
        )

    async def analyze(
        self, request: IcebreakerRequest, request_id: str
    ) -> IcebreakerResponse:
        """執行破冰分析，回傳場景分析與搭訕建議。"""
        log = logger.bind(request_id=request_id, feature="icebreaker")

        if self._flags.ENABLE_MOCK_MODE:
            log.info("returning_mock_response")
            return MOCK_ICEBREAKER_RESPONSE

        if not request.scene_description and not request.image_base64:
            raise InvalidInputError("At least scene_description or image is required")

        user_prompt = self._build_user_prompt(request)
        log.info("calling_llm", has_image=bool(request.image_base64))

        # 計時 LLM 呼叫
        t0 = time.monotonic()
        try:
            raw = await self._call_llm(self._llm, request, user_prompt, request_id)
            latency_ms = int((time.monotonic() - t0) * 1000)
            result = self._parse_response(raw)
            # 非同步寫入日誌（成功）
            await self._write_log(request, raw, latency_ms, request_id)
            return result
        except Exception as e:
            latency_ms = int((time.monotonic() - t0) * 1000)
            # 寫入錯誤日誌
            await self._write_log(request, None, latency_ms, request_id, status="error", error_msg=str(e))
            raise

    def _build_user_prompt(self, request: IcebreakerRequest) -> str:
        """根據請求內容組合使用者提示詞。"""
        parts = []
        if request.scene_description:
            parts.append(f"場景描述：{request.scene_description}")
        if request.image_base64:
            parts.append("請分析附帶的照片中的場景和人物。")
        parts.append(f"請用{request.language}回覆。")
        return "\n".join(parts)

    def _parse_response(self, raw: dict) -> IcebreakerResponse:
        """將 LLM 原始回應解析為結構化的破冰回應物件。"""
        observation_hooks = [
            ObservationHook(
                detail=hook.get("detail", ""),
                hook_type=hook.get("hook_type", ""),
            )
            for hook in raw.get("observation_hooks", [])
        ]
        opening_lines = [
            OpeningLine(
                text=line.get("text", ""),
                tone=line.get("tone", "unknown"),
                confidence=float(line.get("confidence", 0.5)),
                based_on=line.get("based_on", ""),
            )
            for line in raw.get("opening_lines", [])
        ]
        topic_suggestions = [
            TopicSuggestion(
                topic=ts.get("topic", ""),
                context=ts.get("context", ""),
            )
            for ts in raw.get("topic_suggestions", [])
        ]
        return IcebreakerResponse(
            scene_analysis=raw.get("scene_analysis", ""),
            approach_readiness=raw.get("approach_readiness", ""),
            observation_hooks=observation_hooks,
            opening_lines=opening_lines,
            topic_suggestions=topic_suggestions,
            behavior_tips=raw.get("behavior_tips", []),
        )
