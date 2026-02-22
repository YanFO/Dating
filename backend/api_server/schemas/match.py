"""Match API 請求/回應 DTO

定義 Match 管線端點的 Pydantic 驗證模型。
負責 HTTP 層的輸入驗證與序列化，不含業務邏輯。

端點對應：
- POST   /api/matches       → MatchCreateRequest
- PUT    /api/matches/<id>  → MatchUpdateRequest
- 回應統一使用 MatchResponse
"""

from typing import Optional

from pydantic import BaseModel, field_validator

from config.constants import MAX_CONTEXT_TAG_LENGTH, MAX_MATCH_NAME_LENGTH


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
