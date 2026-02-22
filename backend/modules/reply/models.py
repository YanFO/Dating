"""回覆教練模組的資料模型定義。"""

from dataclasses import dataclass, field, asdict
from typing import Optional


@dataclass
class EmotionAnalysis:
    """情緒分析結果，包含偵測到的情緒、潛台詞及信心分數。"""
    detected_emotion: str
    subtext: str
    confidence: float


@dataclass
class ReplyOption:
    """回覆選項，包含建議文字、意圖、策略及使用的框架技巧。"""
    text: str
    intent: str
    strategy: str
    framework_technique: str = ""


@dataclass
class CoachPanel:
    """教練面板，提供觀點說明及行為建議的正反面清單。"""
    perspective_note: str
    dos: list[str] = field(default_factory=list)
    donts: list[str] = field(default_factory=list)


@dataclass
class StageCoaching:
    """階段性指導，根據目前關係階段提供策略與注意事項。"""
    current_stage: str
    stage_strategy: str
    technique_used: str
    stage_warnings: list[str] = field(default_factory=list)


@dataclass
class ReplyRequest:
    """回覆分析請求，可包含聊天文字或截圖及關係階段等參數。"""
    chat_text: Optional[str] = None
    screenshot_base64: Optional[str] = None
    language: str = "zh-TW"
    relationship_stage: str = "early"
    user_gender: str = "male"
    target_gender: str = "female"


@dataclass
class ReplyResponse:
    """回覆分析回應，包含情緒分析、回覆選項、教練面板及階段指導。"""
    emotion_analysis: EmotionAnalysis
    reply_options: list[ReplyOption] = field(default_factory=list)
    coach_panel: Optional[CoachPanel] = None
    stage_coaching: Optional[StageCoaching] = None

    def to_dict(self) -> dict:
        """將回應物件轉換為字典格式。"""
        return asdict(self)
