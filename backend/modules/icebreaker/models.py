from dataclasses import dataclass, field, asdict
from typing import Optional


@dataclass
class OpeningLine:
    text: str
    tone: str
    confidence: float


@dataclass
class IcebreakerRequest:
    scene_description: str = ""
    image_base64: Optional[str] = None
    language: str = "zh-TW"


@dataclass
class IcebreakerResponse:
    scene_analysis: str
    opening_lines: list[OpeningLine] = field(default_factory=list)
    behavior_tips: list[str] = field(default_factory=list)

    def to_dict(self) -> dict:
        return asdict(self)
