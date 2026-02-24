"""OpenAI LLM 客户端模块，提供图像分析与文本分析功能，支持推理模型。"""

import asyncio

import httpx
import openai
import orjson
import structlog

from config.constants import LLM_VISION_TIMEOUT, LLM_TEXT_TIMEOUT

logger = structlog.get_logger()


class OpenAIClient:
    """OpenAI 客户端，封装 GPT 系列与 o 系列推理模型的调用逻辑。"""

    def __init__(self, api_key: str, model: str = "gpt-4o"):
        """初始化 OpenAI 客户端，自动检测是否为推理模型并配置超时。"""
        self._model = model
        self._is_reasoning = self._detect_reasoning_model(model)
        self._client = openai.AsyncOpenAI(
            api_key=api_key,
            timeout=httpx.Timeout(
                connect=2.0,
                read=120.0 if self._is_reasoning else 45.0,
                write=10.0,
                pool=5.0,
            ),
            max_retries=2,
        )

    @staticmethod
    def _detect_reasoning_model(model: str) -> bool:
        """检测是否为 o 系列/思维链推理模型，这类模型需要不同的 API 参数。"""
        m = model.lower()
        return "thinking" in m or m.startswith("o1") or m.startswith("o3") or m.startswith("o4")

    def _build_params(self, messages: list[dict]) -> dict:
        """根据模型类型构建适配的补全请求参数。"""
        params: dict = {"model": self._model, "messages": messages}
        params["max_completion_tokens"] = 4096
        if not self._is_reasoning:
            params["response_format"] = {"type": "json_object"}
        return params

    async def analyze_image(
        self,
        image_base64: str,
        system_prompt: str,
        user_prompt: str,
        request_id: str,
    ) -> dict:
        """发送图像与提示词至 OpenAI 进行视觉分析，返回 JSON 结果。"""
        log = logger.bind(request_id=request_id, method="analyze_image", model=self._model)
        log.info("openai_vision_call_start")

        combined_prompt = f"{system_prompt}\n\n{user_prompt}" if self._is_reasoning else user_prompt

        # Normalise data-URI: accept both raw base64 and prefixed
        image_url = image_base64 if image_base64.startswith("data:") else f"data:image/jpeg;base64,{image_base64}"

        messages = []
        if not self._is_reasoning:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({
            "role": "user",
            "content": [
                {"type": "text", "text": combined_prompt},
                {
                    "type": "image_url",
                    "image_url": {
                        "url": image_url,
                        "detail": "high",
                    },
                },
            ],
        })

        timeout = 120.0 if self._is_reasoning else LLM_VISION_TIMEOUT
        response = await asyncio.wait_for(
            self._client.chat.completions.create(**self._build_params(messages)),
            timeout=timeout,
        )
        content = response.choices[0].message.content
        log.info("openai_vision_call_done")
        return self._extract_json(content)

    async def analyze_images(
        self,
        images_base64: list[str],
        system_prompt: str,
        user_prompt: str,
        request_id: str,
    ) -> list[dict]:
        """发送多张图像至 OpenAI 进行批量视觉分析，返回 JSON 数组。"""
        log = logger.bind(request_id=request_id, method="analyze_images", model=self._model, image_count=len(images_base64))
        log.info("openai_multi_vision_call_start")

        combined_prompt = f"{system_prompt}\n\n{user_prompt}" if self._is_reasoning else user_prompt

        content_parts: list[dict] = [{"type": "text", "text": combined_prompt}]
        for img_b64 in images_base64:
            image_url = img_b64 if img_b64.startswith("data:") else f"data:image/jpeg;base64,{img_b64}"
            content_parts.append({
                "type": "image_url",
                "image_url": {"url": image_url, "detail": "high"},
            })

        messages = []
        if not self._is_reasoning:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": content_parts})

        timeout = 120.0 if self._is_reasoning else LLM_VISION_TIMEOUT * 2
        response = await asyncio.wait_for(
            self._client.chat.completions.create(**self._build_params(messages)),
            timeout=timeout,
        )
        content = response.choices[0].message.content
        log.info("openai_multi_vision_call_done")
        result = self._extract_json(content)
        # Ensure we always return a list
        if isinstance(result, dict):
            return [result]
        return result

    async def analyze_text(
        self,
        system_prompt: str,
        user_prompt: str,
        request_id: str,
    ) -> dict:
        """发送纯文本提示词至 OpenAI 进行分析，返回 JSON 结果。"""
        log = logger.bind(request_id=request_id, method="analyze_text", model=self._model)
        log.info("openai_text_call_start")

        messages = []
        if self._is_reasoning:
            messages.append({"role": "user", "content": f"{system_prompt}\n\n{user_prompt}"})
        else:
            messages.append({"role": "system", "content": system_prompt})
            messages.append({"role": "user", "content": user_prompt})

        timeout = 120.0 if self._is_reasoning else LLM_TEXT_TIMEOUT
        response = await asyncio.wait_for(
            self._client.chat.completions.create(**self._build_params(messages)),
            timeout=timeout,
        )
        content = response.choices[0].message.content
        log.info("openai_text_call_done")
        return self._extract_json(content)

    @staticmethod
    def _extract_json(content: str) -> dict:
        """从响应中提取 JSON，处理推理模型返回的 Markdown 代码块格式。"""
        text = content.strip()
        if text.startswith("```"):
            lines = text.split("\n")
            lines = lines[1:]  # skip ```json or ```
            if lines and lines[-1].strip() == "```":
                lines = lines[:-1]
            text = "\n".join(lines)
        return orjson.loads(text)

    async def close(self):
        """关闭 OpenAI 异步客户端连接。"""
        await self._client.close()