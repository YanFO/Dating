"""Match API 請求/回應 DTO

定義 Match 管線與 Memory 端點的 Pydantic 驗證模型。
負責 HTTP 層的輸入驗證與序列化，不含業務邏輯。

端點對應：
- POST   /api/matches                      → MatchCreateRequest
- PUT    /api/matches/<id>                  → MatchUpdateRequest
- PUT    /api/matches/<id>/memory           → MemoryUpsertRequest
"""

from typing import Optional

from pydantic import BaseModel, field_validator

from config.constants import MAX_CHAT_IMPORT_TEXT_LENGTH, MAX_CONTEXT_TAG_LENGTH, MAX_MATCH_NAME_LENGTH


class ChatImportRequest(BaseModel):
    """聊天記錄匯入請求（文字模式）

    Request Body:
        chat_text (str, 必填): 聊天文字內容
    """

    chat_text: str

    @field_validator("chat_text")
    @classmethod
    def validate_chat_text(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("chat_text is required and cannot be empty")
        if len(v) > MAX_CHAT_IMPORT_TEXT_LENGTH:
            raise ValueError(f"chat_text exceeds {MAX_CHAT_IMPORT_TEXT_LENGTH} characters")
        return v


class MatchCreateRequest(BaseModel):
    """新增 Match 請求

    Request Body:
        name (str, 必填): 對方姓名或暱稱，最長 128 字
        context_tag (str, 選填): 場景標籤，如 "Art Gallery"，最長 128 字
    """

    name: str
    context_tag: Optional[str] = None

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        """驗證姓名：不可空白、不可超過最大長度"""
        v = v.strip()
        if not v:
            raise ValueError("name is required and cannot be empty")
        if len(v) > MAX_MATCH_NAME_LENGTH:
            raise ValueError(f"name exceeds {MAX_MATCH_NAME_LENGTH} characters")
        return v

    @field_validator("context_tag")
    @classmethod
    def validate_context_tag(cls, v: Optional[str]) -> Optional[str]:
        """驗證場景標籤：若有提供則不可超過最大長度"""
        if v is not None:
            v = v.strip()
            if len(v) > MAX_CONTEXT_TAG_LENGTH:
                raise ValueError(f"context_tag exceeds {MAX_CONTEXT_TAG_LENGTH} characters")
        return v


class MatchUpdateRequest(BaseModel):
    """更新 Match 請求

    Request Body（所有欄位選填，至少提供一個）:
        name (str, 選填): 新姓名
        context_tag (str, 選填): 新場景標籤
        status (str, 選填): 新狀態（"active" 或 "archived"）
    """

    name: Optional[str] = None
    context_tag: Optional[str] = None
    status: Optional[str] = None

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: Optional[str]) -> Optional[str]:
        """驗證姓名：若有提供則不可空白、不可超過最大長度"""
        if v is not None:
            v = v.strip()
            if not v:
                raise ValueError("name cannot be empty")
            if len(v) > MAX_MATCH_NAME_LENGTH:
                raise ValueError(f"name exceeds {MAX_MATCH_NAME_LENGTH} characters")
        return v

    @field_validator("status")
    @classmethod
    def validate_status(cls, v: Optional[str]) -> Optional[str]:
        """驗證狀態：僅允許 active 或 archived"""
        if v is not None and v not in ("active", "archived"):
            raise ValueError("status must be 'active' or 'archived'")
        return v


class MemoryUpsertRequest(BaseModel):
    """Memory Profile 部分更新請求 — 所有欄位皆為選填，只覆蓋有傳入的欄位"""

    # 1. 基本資訊與重要節日
    birthday: Optional[str] = None
    anniversaries: Optional[list] = None
    mbti_or_zodiac: Optional[str] = None
    routine: Optional[list] = None
    # 2. 飲食偏好
    favorite_food: Optional[list] = None
    favorite_restaurant: Optional[list] = None
    disliked_food: Optional[list] = None
    dietary_restrictions: Optional[list] = None
    beverage_customization: Optional[list] = None
    # 3. 地點與休閒娛樂
    favorite_places: Optional[list] = None
    travel_wishlist: Optional[list] = None
    hobbies: Optional[list] = None
    entertainment_tastes: Optional[list] = None
    # 4. 情感地雷與情緒撫慰
    landmines: Optional[list] = None
    pet_peeves: Optional[list] = None
    soothing_methods: Optional[list] = None
    love_languages: Optional[list] = None
    # 5. 物質與送禮
    wishlist: Optional[list] = None
    favorite_brands: Optional[list] = None
    aesthetic_preference: Optional[list] = None
    # 6. 其他
    other_notes: Optional[list] = None

    def to_update_dict(self) -> dict:
        """只回傳有值的欄位（用於部分更新）"""
        return {k: v for k, v in self.model_dump().items() if v is not None}
