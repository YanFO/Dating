import structlog

from modules.reply.errors import ChatAnalysisFailed, NoInputProvided
from modules.reply.models import (
    CoachPanel,
    EmotionAnalysis,
    ReplyOption,
    ReplyRequest,
    ReplyResponse,
)
from modules.reply.prompts import REPLY_SYSTEM_PROMPT

logger = structlog.get_logger()

MOCK_REPLY_RESPONSE = ReplyResponse(
    emotion_analysis=EmotionAnalysis(
        detected_emotion="略帶敷衍但仍有興趣",
        subtext="對方回覆雖短，但使用了表情符號且回覆速度正常，表示仍有基本興趣，但需要更有趣的話題來提升互動品質。",
        confidence=0.78,
    ),
    reply_options=[
        ReplyOption(
            text="哈哈我也是這樣覺得～對了你週末通常都在幹嘛？",
            tone="humorous",
            strategy="話題轉移 + 開放式提問",
        ),
        ReplyOption(
            text="欸認真問，你有沒有特別推薦的餐廳？我最近一直吃到雷",
            tone="sincere",
            strategy="請教式互動，降低需求感",
        ),
        ReplyOption(
            text="所以你是那種外表高冷但其實很有趣的人齁 😏",
            tone="flirty",
            strategy="輕微挑逗，測試對方反應",
        ),
    ],
    coach_panel=CoachPanel(
        explanation="對方目前的回覆屬於「低投資回覆」，這是正常的初期互動模式。關鍵是不要急著追問或連發訊息，而是用有趣的話題吸引對方主動投入更多。",
        recommended_strategy="價值展示 + 話題引導",
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
)


class ReplyService:
    def __init__(self, llm_client, feature_flags):
        self._llm = llm_client
        self._flags = feature_flags

    async def analyze(
        self, request: ReplyRequest, request_id: str
    ) -> ReplyResponse:
        log = logger.bind(request_id=request_id, feature="reply")

        if self._flags.ENABLE_MOCK_MODE:
            log.info("returning_mock_response")
            return MOCK_REPLY_RESPONSE

        if not request.chat_text and not request.screenshot_base64:
            raise NoInputProvided("At least chat_text or screenshot is required")

        user_prompt = self._build_user_prompt(request)
        log.info("calling_llm", has_screenshot=bool(request.screenshot_base64))

        try:
            if request.screenshot_base64:
                raw = await self._llm.analyze_image(
                    image_base64=request.screenshot_base64,
                    system_prompt=REPLY_SYSTEM_PROMPT,
                    user_prompt=user_prompt,
                    request_id=request_id,
                )
            else:
                raw = await self._llm.analyze_text(
                    system_prompt=REPLY_SYSTEM_PROMPT,
                    user_prompt=user_prompt,
                    request_id=request_id,
                )
        except Exception as e:
            log.error("llm_call_failed", error=str(e))
            raise ChatAnalysisFailed(str(e)) from e

        return self._parse_response(raw)

    def _build_user_prompt(self, request: ReplyRequest) -> str:
        parts = []
        if request.chat_text:
            parts.append(f"聊天記錄：\n{request.chat_text}")
        if request.screenshot_base64:
            parts.append("請分析附帶的聊天截圖。")
        parts.append(f"請用{request.language}回覆。")
        return "\n".join(parts)

    def _parse_response(self, raw: dict) -> ReplyResponse:
        ea_raw = raw.get("emotion_analysis", {})
        emotion_analysis = EmotionAnalysis(
            detected_emotion=ea_raw.get("detected_emotion", ""),
            subtext=ea_raw.get("subtext", ""),
            confidence=float(ea_raw.get("confidence", 0.5)),
        )
        reply_options = [
            ReplyOption(
                text=opt.get("text", ""),
                tone=opt.get("tone", "unknown"),
                strategy=opt.get("strategy", ""),
            )
            for opt in raw.get("reply_options", [])
        ]
        cp_raw = raw.get("coach_panel", {})
        coach_panel = CoachPanel(
            explanation=cp_raw.get("explanation", ""),
            recommended_strategy=cp_raw.get("recommended_strategy", ""),
            dos=cp_raw.get("dos", []),
            donts=cp_raw.get("donts", []),
        )
        return ReplyResponse(
            emotion_analysis=emotion_analysis,
            reply_options=reply_options,
            coach_panel=coach_panel,
        )
