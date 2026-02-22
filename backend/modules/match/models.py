"""Match 領域模型

定義約會管線（Active Pipeline）中的 Match 資料結構。
對應 Flutter Home 頁的水平滾動 Match 卡片列表。
"""

from dataclasses import asdict, dataclass
from typing import Optional


@dataclass
class MatchRecord:
    """單筆約會對象記錄

    Attributes:
        match_id: 唯一識別碼（格式: match_{hex16}）
        user_id: 所屬用戶 ID
        name: 對方姓名或暱稱
        context_tag: 場景標籤（如 "Art Gallery"、"Coffee fan"）
        status: 狀態（active / archived）
        created_at: 建立時間 ISO8601
        updated_at: 最後更新時間 ISO8601
    """

    match_id: str
    user_id: str
    name: str
    context_tag: Optional[str] = None
    status: str = "active"
    created_at: str = ""
    updated_at: str = ""

    def to_dict(self) -> dict:
        """轉換為 dict 供 API 回傳使用"""
        return asdict(self)
