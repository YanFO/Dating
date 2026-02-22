"""Persona API 請求/回應 DTO

定義數位人格端點的 Pydantic 驗證模型。
負責 HTTP 層的輸入驗證與序列化，不含業務邏輯。

端點對應：
- PUT    /api/persona/tone     → ToneUpdateRequest
- POST   /api/persona/sandbox  → SandboxRequest
"""

from pydantic import BaseModel, field_validator

from config.constants import MAX_SANDBOX_TEXT_LENGTH


class ToneUpdateRequest(BaseModel):
    """更新語調設定請求

    Request Body:
        emoji_usage (float, 必填): Emoji 使用量，0-100
        sentence_length (float, 必填): 句子長度偏好，0-100
        colloquialism (float, 必填): 口語程度，0-100
    """

    emoji_usage: float
    sentence_length: float
    colloquialism: float

    @field_validator("emoji_usage", "sentence_length", "colloquialism")
    @classmethod
    def validate_range(cls, v: float) -> float:
        """驗證滑桿值：必須在 0-100 範圍內"""
        if not 0 <= v <= 100:
            raise ValueError("value must be between 0 and 100")
        return v


class SandboxRequest(BaseModel):
    """沙盒改寫請求

    Request Body:
        text (str, 必填): 要改寫的原始訊息，最長 500 字
    """

    text: str

    @field_validator("text")
    @classmethod
    def validate_text(cls, v: str) -> str:
        """驗證改寫文字：不可空白、不可超過最大長度"""
        v = v.strip()
        if not v:
            raise ValueError("text is required and cannot be empty")
        if len(v) > MAX_SANDBOX_TEXT_LENGTH:
            raise ValueError(f"text exceeds {MAX_SANDBOX_TEXT_LENGTH} characters")
        return v
