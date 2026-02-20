import asyncio

import httpx
import openai
import orjson
import structlog

from config.constants import LLM_VISION_TIMEOUT, LLM_TEXT_TIMEOUT

logger = structlog.get_logger()


class OpenAIClientError(Exception):
    pass


class OpenAITimeoutError(OpenAIClientError):
    pass


class OpenAIAPIError(OpenAIClientError):
    pass


class OpenAIClient:
    def __init__(self, api_key: str):
        self._client = openai.AsyncOpenAI(
            api_key=api_key,
            timeout=httpx.Timeout(
                connect=2.0,
                read=45.0,
                write=10.0,
                pool=5.0,
            ),
            max_retries=2,
        )

    async def analyze_image(
        self,
        image_base64: str,
        system_prompt: str,
        user_prompt: str,
        request_id: str,
    ) -> dict:
        log = logger.bind(request_id=request_id, method="analyze_image")
        log.info("openai_vision_call_start")
        try:
            response = await asyncio.wait_for(
                self._client.chat.completions.create(
                    model="gpt-4o",
                    messages=[
                        {"role": "system", "content": system_prompt},
                        {
                            "role": "user",
                            "content": [
                                {"type": "text", "text": user_prompt},
                                {
                                    "type": "image_url",
                                    "image_url": {
                                        "url": f"data:image/jpeg;base64,{image_base64}",
                                        "detail": "high",
                                    },
                                },
                            ],
                        },
                    ],
                    response_format={"type": "json_object"},
                    max_tokens=2000,
                ),
                timeout=LLM_VISION_TIMEOUT,
            )
            content = response.choices[0].message.content
            log.info("openai_vision_call_done")
            return orjson.loads(content)
        except asyncio.TimeoutError:
            log.error("openai_vision_timeout")
            raise OpenAITimeoutError(f"Vision call timed out for request {request_id}")
        except openai.APIError as e:
            log.error("openai_api_error", error=str(e))
            raise OpenAIAPIError(str(e)) from e

    async def analyze_text(
        self,
        system_prompt: str,
        user_prompt: str,
        request_id: str,
    ) -> dict:
        log = logger.bind(request_id=request_id, method="analyze_text")
        log.info("openai_text_call_start")
        try:
            response = await asyncio.wait_for(
                self._client.chat.completions.create(
                    model="gpt-4o",
                    messages=[
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": user_prompt},
                    ],
                    response_format={"type": "json_object"},
                    max_tokens=2000,
                ),
                timeout=LLM_TEXT_TIMEOUT,
            )
            content = response.choices[0].message.content
            log.info("openai_text_call_done")
            return orjson.loads(content)
        except asyncio.TimeoutError:
            log.error("openai_text_timeout")
            raise OpenAITimeoutError(f"Text call timed out for request {request_id}")
        except openai.APIError as e:
            log.error("openai_api_error", error=str(e))
            raise OpenAIAPIError(str(e)) from e

    async def close(self):
        await self._client.close()
