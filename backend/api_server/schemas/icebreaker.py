"""破冰开场白请求模型模块，定义分析请求的校验规则。"""

from typing import Optional

from pydantic import BaseModel, field_validator

from config.constants import MAX_SCENE_DESCRIPTION_LENGTH
from modules.icebreaker.models import IcebreakerRequest


class IcebreakerAnalyzeRequest(BaseModel):
    """破冰分析请求模型，支持场景描述文字或图片 base64 输入。"""

    scene_description: str = ""
    image_base64: Optional[str] = None
    language: str = "zh-TW"

    @field_validator("scene_description")
    @classmethod
    def validate_scene_description(cls, v: str) -> str:
        """校验场景描述长度不超过上限。"""
        if v and len(v) > MAX_SCENE_DESCRIPTION_LENGTH:
            raise ValueError(
                f"scene_description exceeds {MAX_SCENE_DESCRIPTION_LENGTH} characters"
            )
        return v.strip()

    def to_domain_model(self) -> IcebreakerRequest:
        """将请求模型转换为领域模型对象。"""
        return IcebreakerRequest(
            scene_description=self.scene_description,
            image_base64=self.image_base64,
            language=self.language,
        )
