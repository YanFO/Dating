from typing import Optional

from pydantic import BaseModel, field_validator

from config.constants import MAX_SCENE_DESCRIPTION_LENGTH
from modules.icebreaker.models import IcebreakerRequest


class IcebreakerAnalyzeRequest(BaseModel):
    scene_description: str = ""
    image_base64: Optional[str] = None
    language: str = "zh-TW"

    @field_validator("scene_description")
    @classmethod
    def validate_scene_description(cls, v: str) -> str:
        if v and len(v) > MAX_SCENE_DESCRIPTION_LENGTH:
            raise ValueError(
                f"scene_description exceeds {MAX_SCENE_DESCRIPTION_LENGTH} characters"
            )
        return v.strip()

    def to_domain_model(self) -> IcebreakerRequest:
        return IcebreakerRequest(
            scene_description=self.scene_description,
            image_base64=self.image_base64,
            language=self.language,
        )
