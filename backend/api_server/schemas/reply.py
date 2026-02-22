"""回复教练请求模型模块，定义聊天分析请求的校验规则。"""

from typing import Optional

from pydantic import BaseModel, field_validator, model_validator

from config.constants import MAX_CHAT_TEXT_LENGTH
from modules.reply.models import ReplyRequest

VALID_RELATIONSHIP_STAGES = ("early", "flirting", "couple")
VALID_GENDERS = ("male", "female")


class ReplyAnalyzeRequest(BaseModel):
    """回复分析请求模型，支持聊天文字或截图输入，含关系阶段和性别参数。"""

    chat_text: Optional[str] = None
    screenshot_base64: Optional[str] = None
    language: str = "zh-TW"
    relationship_stage: str = "early"
    user_gender: str = "male"
    target_gender: str = "female"

    @field_validator("relationship_stage")
    @classmethod
    def validate_relationship_stage(cls, v: str) -> str:
        """校验关系阶段字段值是否合法。"""
        if v not in VALID_RELATIONSHIP_STAGES:
            raise ValueError(
                f"relationship_stage must be one of {VALID_RELATIONSHIP_STAGES}, got '{v}'"
            )
        return v

    @field_validator("user_gender", "target_gender")
    @classmethod
    def validate_gender(cls, v: str) -> str:
        """校验性别字段值是否合法。"""
        if v not in VALID_GENDERS:
            raise ValueError(
                f"gender must be one of {VALID_GENDERS}, got '{v}'"
            )
        return v

    @model_validator(mode="after")
    def validate_at_least_one_input(self):
        """校验至少提供一种输入（聊天文字或截图），并检查文字长度。"""
        if not self.chat_text and not self.screenshot_base64:
            raise ValueError("At least one of chat_text or screenshot_base64 is required")
        if self.chat_text and len(self.chat_text) > MAX_CHAT_TEXT_LENGTH:
            raise ValueError(
                f"chat_text exceeds {MAX_CHAT_TEXT_LENGTH} characters"
            )
        return self

    def to_domain_model(self) -> ReplyRequest:
        """将请求模型转换为领域模型对象。"""
        return ReplyRequest(
            chat_text=self.chat_text,
            screenshot_base64=self.screenshot_base64,
            language=self.language,
            relationship_stage=self.relationship_stage,
            user_gender=self.user_gender,
            target_gender=self.target_gender,
        )
