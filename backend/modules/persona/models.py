"""Persona 領域模型

定義用戶數位人格（AI Clone）的語調設定與沙盒測試結果。
對應 Flutter Profile 頁的語調滑桿與沙盒改寫功能。
"""

from dataclasses import asdict, dataclass


@dataclass
class PersonaSettings:
    """用戶人格語調設定

    Attributes:
        user_id: 所屬用戶 ID
        sync_pct: AI 分身同步百分比（0-100）
        emoji_usage: Emoji 使用量（0-100，None→Moderate→Lots）
        sentence_length: 句子長度偏好（0-100，Brief→Short→Detailed）
        colloquialism: 口語程度（0-100，Formal→Casual→Slang）
    """

    user_id: str
    sync_pct: float = 0.0
    emoji_usage: float = 50.0
    sentence_length: float = 50.0
    colloquialism: float = 50.0

    def to_dict(self) -> dict:
        """轉換為 dict 供 API 回傳使用"""
        return asdict(self)


@dataclass
class SandboxResult:
    """沙盒改寫結果

    Attributes:
        original: 用戶輸入的原始文字
        rewritten: AI 根據語調設定改寫後的文字
    """

    original: str
    rewritten: str

    def to_dict(self) -> dict:
        """轉換為 dict 供 API 回傳使用"""
        return asdict(self)
