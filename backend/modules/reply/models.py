from dataclasses import dataclass, field, asdict
from typing import Optional


@dataclass
class EmotionAnalysis:
    detected_emotion: str
    subtext: str
    confidence: float


@dataclass
class ReplyOption:
    text: str
    tone: str
    strategy: str


@dataclass
class CoachPanel:
    explanation: str
    recommended_strategy: str
    dos: list[str] = field(default_factory=list)
    donts: list[str] = field(default_factory=list)


@dataclass
class ReplyRequest:
    chat_text: Optional[str] = None
    screenshot_base64: Optional[str] = None
    language: str = "zh-TW"


@dataclass
class ReplyResponse:
    emotion_analysis: EmotionAnalysis
    reply_options: list[ReplyOption] = field(default_factory=list)
    coach_panel: Optional[CoachPanel] = None

    def to_dict(self) -> dict:
        return asdict(self)
