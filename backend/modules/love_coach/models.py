"""Love Coach 模組的領域模型定義

包含聊天訊息、聊天請求與對話摘要的資料結構，
供服務層與路由層之間傳遞使用。
"""

from dataclasses import dataclass, field, asdict
from datetime import datetime
from typing import Literal, Optional


# ─── 聊天訊息 ─────────────────────────────────────

@dataclass
class ChatMessage:
    """單則聊天訊息，包含角色與文字內容"""
    role: Literal["user", "model"]
    text: str


# ─── 聊天請求 ─────────────────────────────────────

@dataclass
class LoveCoachChatRequest:
    """Love Coach 聊天請求，包含當前訊息與可選的對話 ID"""
    message: str
    conversation_id: Optional[str] = None
    language: str = "zh-TW"


# ─── 對話摘要（列表用）────────────────────────────

@dataclass
class ConversationSummary:
    """對話摘要，用於對話列表顯示"""
    id: str
    title: Optional[str]
    message_count: int
    created_at: str
    updated_at: str

    def to_dict(self) -> dict:
        """轉換為字典格式以供 JSON 序列化"""
        return asdict(self)


# ─── 對話歷史訊息（含時間戳）─────────────────────

@dataclass
class MessageWithTimestamp:
    """帶時間戳的聊天訊息，用於對話歷史回傳"""
    id: str
    role: str
    text: str
    created_at: str

    def to_dict(self) -> dict:
        """轉換為字典格式以供 JSON 序列化"""
        return asdict(self)
