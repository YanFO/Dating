from typing import Optional

from pydantic import BaseModel, model_validator

from config.constants import MAX_CHAT_TEXT_LENGTH
from modules.reply.models import ReplyRequest


class ReplyAnalyzeRequest(BaseModel):
    chat_text: Optional[str] = None
    screenshot_base64: Optional[str] = None
    language: str = "zh-TW"

    @model_validator(mode="after")
    def validate_at_least_one_input(self):
        if not self.chat_text and not self.screenshot_base64:
            raise ValueError("At least one of chat_text or screenshot_base64 is required")
        if self.chat_text and len(self.chat_text) > MAX_CHAT_TEXT_LENGTH:
            raise ValueError(
                f"chat_text exceeds {MAX_CHAT_TEXT_LENGTH} characters"
            )
        return self

    def to_domain_model(self) -> ReplyRequest:
        return ReplyRequest(
            chat_text=self.chat_text,
            screenshot_base64=self.screenshot_base64,
            language=self.language,
        )
