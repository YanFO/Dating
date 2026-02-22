"""搭訕破冰模組的資料模型定義。"""

from dataclasses import dataclass, field, asdict
from typing import Optional


@dataclass
class ObservationHook:
    """觀察切入點，描述可用於開場的細節及其類型。"""
    detail: str
    hook_type: str  # "compliment" | "common_ground" | "environmental" | "care"


@dataclass
class TopicSuggestion:
    """話題建議，包含主題及其適用的情境說明。"""
    topic: str
    context: str


@dataclass
class OpeningLine:
    """開場白建議，包含文字、語氣、信心分數及依據。"""
    text: str
    tone: str
    confidence: float
    based_on: str = ""


@dataclass
class IcebreakerRequest:
    """破冰分析請求，可包含場景描述或圖片。"""
    scene_description: str = ""
    image_base64: Optional[str] = None
    language: str = "zh-TW"


@dataclass
class IcebreakerResponse:
    """破冰分析回應，包含場景分析、開場白、話題建議等完整結果。"""
    scene_analysis: str
    approach_readiness: str = ""
    observation_hooks: list[ObservationHook] = field(default_factory=list)
    opening_lines: list[OpeningLine] = field(default_factory=list)
    topic_suggestions: list[TopicSuggestion] = field(default_factory=list)
    behavior_tips: list[str] = field(default_factory=list)

    def to_dict(self) -> dict:
        """將回應物件轉換為字典格式。"""
        return asdict(self)
