"""Google Gemini LLM 客户端模块，提供图像分析、文本分析与串流聊天功能。"""

import asyncio
import base64
from typing import AsyncGenerator

import orjson
import structlog
from google import genai
from google.genai import types

from config.constants import (
    LLM_VISION_TIMEOUT,
    LLM_TEXT_TIMEOUT,
    LLM_CHAT_STREAM_TOTAL_TIMEOUT,
)

logger = structlog.get_logger()


class GeminiClient:
    """Google Gemini 客户端，支持图像视觉分析与纯文本分析。

    使用 google-genai SDK 的异步接口。
    """

    def __init__(self, api_key: str, model: str = "gemini-3-pro-preview"):
        """初始化 Gemini 客户端，设置 API 密钥与模型名称。"""
        self._client = genai.Client(api_key=api_key)
        self._model = model

    async def analyze_image(
        self,
        image_base64: str,
        system_prompt: str,
        user_prompt: str,
        request_id: str,
    ) -> dict:
        """发送图像与提示词至 Gemini 进行视觉分析，返回 JSON 结果。"""
        log = logger.bind(request_id=request_id, method="analyze_image", model=self._model)
        log.info("gemini_vision_call_start")

        # Decode base64 to bytes for Gemini
        clean_b64 = image_base64
        if "," in clean_b64:
            clean_b64 = clean_b64.split(",", 1)[1]
        image_bytes = base64.b64decode(clean_b64)

        image_part = types.Part.from_bytes(data=image_bytes, mime_type="image/jpeg")
        text_part = types.Part.from_text(text=user_prompt)

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

    async def analyze_text(
        self,
        system_prompt: str,
        user_prompt: str,
        request_id: str,
    ) -> dict:
        """发送纯文本提示词至 Gemini 进行分析，返回 JSON 结果。"""
        log = logger.bind(request_id=request_id, method="analyze_text", model=self._model)
        log.info("gemini_text_call_start")

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

    async def generate_chat_stream(
        self,
        system_prompt: str,
        messages: list[dict],
        request_id: str,
    ) -> AsyncGenerator[str, None]:
        """串流聊天回覆，逐步 yield 文字 chunk。

        Args:
            system_prompt: 系統指令（角色設定）
            messages: 對話歷史，每則為 {"role": "user"|"model", "text": str}
            request_id: 請求追蹤 ID
        """
        log = logger.bind(request_id=request_id, method="chat_stream", model=self._model)
        log.info("gemini_chat_stream_start", message_count=len(messages))

        contents = []
        for msg in messages:
            contents.append(
                types.Content(
                    role=msg["role"],
                    parts=[types.Part.from_text(text=msg["text"])],
                )
            )

        # 整體串流超時保護（避免無限等待）
        deadline = asyncio.get_event_loop().time() + LLM_CHAT_STREAM_TOTAL_TIMEOUT
        chunk_count = 0

        # generate_content_stream() 回傳 Awaitable[AsyncIterator]，需先 await
        stream = await self._client.aio.models.generate_content_stream(
            model=self._model,
            contents=contents,
            config=types.GenerateContentConfig(
                system_instruction=system_prompt,
                max_output_tokens=4096,
                temperature=0.8,
            ),
        )

        async for chunk in stream:
            # 每個 chunk 檢查整體超時
            if asyncio.get_event_loop().time() > deadline:
                log.warning("gemini_chat_stream_total_timeout")
                break

            if chunk.text:
                chunk_count += 1
                yield chunk.text

        log.info("gemini_chat_stream_done", chunks=chunk_count)

    async def close(self):
        """关闭客户端连接（Gemini 客户端无需额外清理）。"""
        pass