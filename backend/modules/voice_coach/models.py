from dataclasses import dataclass, field
from typing import Optional

from utils.time import utcnow, format_iso


@dataclass
class VoiceCoachSession:
    session_id: str
    status: str = "active"
    created_at: str = field(default_factory=lambda: format_iso(utcnow()))


@dataclass
class CoachingEvent:
    type: str  # "suggestion", "topic_change", "awkward_silence_detected", "sentiment_shift"
    payload: dict = field(default_factory=dict)
    timestamp: str = field(default_factory=lambda: format_iso(utcnow()))
