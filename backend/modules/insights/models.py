"""Insights 領域模型

定義成長雷達圖（6 維技能分數）、約會報告及語音教練對話紀錄的資料結構。
對應 Flutter Insights 頁的雷達圖、Post-Date Report 與語音教練分析。
"""

from dataclasses import asdict, dataclass, field


@dataclass
class SkillScores:
    """用戶 6 維約會技能分數（雷達圖數據）

    每項分數範圍 0.0 ~ 1.0，對應 Flutter 雷達圖的 6 個軸：
    - emotional_value: 情感價值
    - listening: 傾聽能力
    - frame_control: 框架控制
    - escalation: 升溫能力
    - empathy: 同理心
    - humor: 幽默感
    """

    emotional_value: float = 0.0
    listening: float = 0.0
    frame_control: float = 0.0
    escalation: float = 0.0
    empathy: float = 0.0
    humor: float = 0.0

    def to_dict(self) -> dict:
        """轉換為 dict 供 API 回傳使用"""
        return asdict(self)


@dataclass
class DateReport:
    """約會後報告

    Attributes:
        report_id: 唯一識別碼（格式: rpt_{hex16}）
        user_id: 所屬用戶 ID
        score: 總分（0-100）
        skills: 該次約會的 6 維技能快照
        good_points: 做得好的項目列表
        to_improve: 待改進的項目列表
        action_items: 行動建議列表
        created_at: 建立時間 ISO8601
    """

    report_id: str
    user_id: str
    score: int = 0
    skills: SkillScores = field(default_factory=SkillScores)
    good_points: list[str] = field(default_factory=list)
    to_improve: list[str] = field(default_factory=list)
    action_items: list[str] = field(default_factory=list)
    created_at: str = ""

    def to_dict(self) -> dict:
        """轉換為 dict 供 API 回傳使用"""
        return asdict(self)


@dataclass
class VoiceCoachLog:
    """語音教練對話紀錄

    Attributes:
        log_id: 紀錄唯一識別碼
        session_id: 語音教練會話 ID
        input_transcripts: 麥克風收音的即時辨識結果列表
        coach_transcripts: AI 教練語音轉寫列表
        coaching_updates: 結構化教練分析結果列表
        duration_ms: 會話持續時間（毫秒）
        created_at: 建立時間 ISO8601
    """

    log_id: str
    session_id: str = ""
    input_transcripts: list[str] = field(default_factory=list)
    coach_transcripts: list[str] = field(default_factory=list)
    coaching_updates: list[dict] = field(default_factory=list)
    duration_ms: int = 0
    created_at: str = ""

    def to_dict(self) -> dict:
        """轉換為 dict 供 API 回傳使用"""
        return asdict(self)
