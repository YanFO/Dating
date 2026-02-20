import structlog

from modules.icebreaker.errors import ImageAnalysisFailed, InvalidInputError
from modules.icebreaker.models import IcebreakerRequest, IcebreakerResponse, OpeningLine
from modules.icebreaker.prompts import ICEBREAKER_SYSTEM_PROMPT

logger = structlog.get_logger()

MOCK_ICEBREAKER_RESPONSE = IcebreakerResponse(
    scene_analysis="咖啡廳場景，對方穿著休閒，正在閱讀一本書，氛圍輕鬆適合搭訕。",
    opening_lines=[
        OpeningLine(
            text="嘿，那本書看起來很有趣，是什麼類型的？",
            tone="friendly_curious",
            confidence=0.92,
        ),
        OpeningLine(
            text="不好意思打擾，我注意到你點的也是拿鐵，這裡的拿鐵真的很讚對吧？",
            tone="casual_warm",
            confidence=0.87,
        ),
        OpeningLine(
            text="你好，我一個人來這裡讀書，發現這個位置的光線最好，你也是嗎？",
            tone="observational",
            confidence=0.85,
        ),
    ],
    behavior_tips=[
        "保持1.2公尺以上的社交距離，不要突然靠近",
        "先微笑再開口，建立視覺友善訊號",
        "身體稍微側身站立，避免正面直對造成壓迫感",
        "如果對方戴著耳機，等待對方摘下後再搭話",
    ],
)


class IcebreakerService:
    def __init__(self, llm_client, feature_flags):
        self._llm = llm_client
        self._flags = feature_flags

    async def analyze(
        self, request: IcebreakerRequest, request_id: str
    ) -> IcebreakerResponse:
        log = logger.bind(request_id=request_id, feature="icebreaker")

        if self._flags.ENABLE_MOCK_MODE:
            log.info("returning_mock_response")
            return MOCK_ICEBREAKER_RESPONSE

        if not request.scene_description and not request.image_base64:
            raise InvalidInputError("At least scene_description or image is required")

        user_prompt = self._build_user_prompt(request)
        log.info("calling_llm", has_image=bool(request.image_base64))

        try:
            if request.image_base64:
                raw = await self._llm.analyze_image(
                    image_base64=request.image_base64,
                    system_prompt=ICEBREAKER_SYSTEM_PROMPT,
                    user_prompt=user_prompt,
                    request_id=request_id,
                )
            else:
                raw = await self._llm.analyze_text(
                    system_prompt=ICEBREAKER_SYSTEM_PROMPT,
                    user_prompt=user_prompt,
                    request_id=request_id,
                )
        except Exception as e:
            log.error("llm_call_failed", error=str(e))
            raise ImageAnalysisFailed(str(e)) from e

        return self._parse_response(raw)

    def _build_user_prompt(self, request: IcebreakerRequest) -> str:
        parts = []
        if request.scene_description:
            parts.append(f"場景描述：{request.scene_description}")
        if request.image_base64:
            parts.append("請分析附帶的照片中的場景和人物。")
        parts.append(f"請用{request.language}回覆。")
        return "\n".join(parts)

    def _parse_response(self, raw: dict) -> IcebreakerResponse:
        opening_lines = [
            OpeningLine(
                text=line.get("text", ""),
                tone=line.get("tone", "unknown"),
                confidence=float(line.get("confidence", 0.5)),
            )
            for line in raw.get("opening_lines", [])
        ]
        return IcebreakerResponse(
            scene_analysis=raw.get("scene_analysis", ""),
            opening_lines=opening_lines,
            behavior_tips=raw.get("behavior_tips", []),
        )
