"""Love Coach 聊天請求的 Pydantic 校驗模型

定義 HTTP 傳輸層的請求格式與驗證規則。
負責將原始 JSON 轉換為領域模型後交由服務層處理。
"""

from typing import Optional

from pydantic import BaseModel, field_validator

from config.constants import MAX_LOVE_COACH_MESSAGE_LENGTH
from modules.love_coach.models import LoveCoachChatRequest


class LoveCoachChatRequestSchema(BaseModel):
    """Love Coach 聊天請求 DTO

    Attributes:
        message: 使用者輸入的訊息（必填，不可為空）
        conversation_id: 既有對話 ID（可選，為空則新建對話）
        language: 回覆語言（預設繁體中文）
    """
    message: str
    conversation_id: Optional[str] = None
    language: str = "zh-TW"

    # ─── 欄位驗證 ──────────────────────────────────

    @field_validator("message")
    @classmethod
    def validate_message(cls, v: str) -> str:
        """驗證訊息：去除前後空白，檢查非空與長度上限"""
        v = v.strip()
        if not v:
            raise ValueError("訊息不可為空")
        if len(v) > MAX_LOVE_COACH_MESSAGE_LENGTH:
            raise ValueError(
                f"訊息超過 {MAX_LOVE_COACH_MESSAGE_LENGTH} 字元上限"
            )
        return v

    # ─── 轉換為領域模型 ────────────────────────────

    def to_domain_model(self) -> LoveCoachChatRequest:
        """將 DTO 轉換為領域模型以供服務層使用"""
        return LoveCoachChatRequest(
            message=self.message,
            conversation_id=self.conversation_id,
            language=self.language,
        )
