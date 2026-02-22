"""語音教練模組的資料模型定義。"""

from dataclasses import dataclass, field
from typing import Optional

from utils.time import utcnow, format_iso


@dataclass
class VoiceCoachSession:
    """語音教練會話，記錄會話 ID、狀態及建立時間。"""
    session_id: str
    status: str = "active"
    created_at: str = field(default_factory=lambda: format_iso(utcnow()))


@dataclass
class CoachingEvent:
    """教練事件，表示一個即時指導事件（如建議、話題轉換、尷尬沉默偵測等）。"""
    type: str  # "suggestion", "topic_change", "awkward_silence_detected", "sentiment_shift"
    payload: dict = field(default_factory=dict)
    timestamp: str = field(default_factory=lambda: format_iso(utcnow()))
