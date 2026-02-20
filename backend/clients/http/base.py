import httpx
import structlog

from config.constants import (
    EXTERNAL_CONNECT_TIMEOUT,
    EXTERNAL_READ_TIMEOUT,
    EXTERNAL_TOTAL_TIMEOUT,
)

logger = structlog.get_logger()


class BaseHTTPClient:
    def __init__(
        self,
        base_url: str = "",
        connect_timeout: float = EXTERNAL_CONNECT_TIMEOUT,
        read_timeout: float = EXTERNAL_READ_TIMEOUT,
        total_timeout: float = EXTERNAL_TOTAL_TIMEOUT,
    ):
        self._client = httpx.AsyncClient(
            base_url=base_url,
            timeout=httpx.Timeout(
                connect=connect_timeout,
                read=read_timeout,
                write=10.0,
                pool=5.0,
            ),
        )
        self._total_timeout = total_timeout

    async def get(
        self, url: str, request_id: str = "", **kwargs
    ) -> httpx.Response:
        headers = kwargs.pop("headers", {})
        headers["X-Request-ID"] = request_id
        resp = await self._client.get(url, headers=headers, **kwargs)
        resp.raise_for_status()
        return resp

    async def post_json(
        self, url: str, json: dict, request_id: str = "", **kwargs
    ) -> httpx.Response:
        headers = kwargs.pop("headers", {})
        headers["X-Request-ID"] = request_id
        resp = await self._client.post(url, json=json, headers=headers, **kwargs)
        resp.raise_for_status()
        return resp

    async def close(self):
        await self._client.aclose()
