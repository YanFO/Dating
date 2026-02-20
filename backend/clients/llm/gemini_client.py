import asyncio
import base64

import orjson
import structlog
from google import genai
from google.genai import types

from config.constants import LLM_VISION_TIMEOUT, LLM_TEXT_TIMEOUT

logger = structlog.get_logger()


class GeminiClientError(Exception):
    pass


class GeminiTimeoutError(GeminiClientError):
    pass


class GeminiAPIError(GeminiClientError):
    pass


class GeminiClient:
    """Google Gemini client for image and text analysis (Feature 1 & 2).

    Uses the google-genai SDK with async support.
    """

    def __init__(self, api_key: str, model: str = "gemini-3-pro-preview"):
        self._client = genai.Client(api_key=api_key)
        self._model = model

    async def analyze_image(
        self,
        image_base64: str,
        system_prompt: str,
        user_prompt: str,
        request_id: str,
    ) -> dict:
        log = logger.bind(request_id=request_id, method="analyze_image", model=self._model)
        log.info("gemini_vision_call_start")

        # Decode base64 to bytes for Gemini
        clean_b64 = image_base64
        if "," in clean_b64:
            clean_b64 = clean_b64.split(",", 1)[1]
        image_bytes = base64.b64decode(clean_b64)

        image_part = types.Part.from_bytes(data=image_bytes, mime_type="image/jpeg")
        text_part = types.Part.from_text(text=user_prompt)

        try:
            response = await asyncio.wait_for(
                self._client.aio.models.generate_content(
                    model=self._model,
                    contents=[image_part, text_part],
                    config=types.GenerateContentConfig(
                        system_instruction=system_prompt,
                        response_mime_type="application/json",
                        max_output_tokens=4096,
                        temperature=0.7,
                    ),
                ),
                timeout=LLM_VISION_TIMEOUT,
            )
            content = response.text
            log.info("gemini_vision_call_done")
            return orjson.loads(content)
        except asyncio.TimeoutError:
            log.error("gemini_vision_timeout")
            raise GeminiTimeoutError(f"Vision call timed out for request {request_id}")
        except Exception as e:
            log.error("gemini_api_error", error=str(e))
            raise GeminiAPIError(str(e)) from e

    async def analyze_text(
        self,
        system_prompt: str,
        user_prompt: str,
        request_id: str,
    ) -> dict:
        log = logger.bind(request_id=request_id, method="analyze_text", model=self._model)
        log.info("gemini_text_call_start")

        try:
            response = await asyncio.wait_for(
                self._client.aio.models.generate_content(
                    model=self._model,
                    contents=user_prompt,
                    config=types.GenerateContentConfig(
                        system_instruction=system_prompt,
                        response_mime_type="application/json",
                        max_output_tokens=4096,
                        temperature=0.7,
                    ),
                ),
                timeout=LLM_TEXT_TIMEOUT,
            )
            content = response.text
            log.info("gemini_text_call_done")
            return orjson.loads(content)
        except asyncio.TimeoutError:
            log.error("gemini_text_timeout")
            raise GeminiTimeoutError(f"Text call timed out for request {request_id}")
        except Exception as e:
            log.error("gemini_api_error", error=str(e))
            raise GeminiAPIError(str(e)) from e

    async def close(self):
        pass
