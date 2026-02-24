import time
from collections import defaultdict

from quart import Quart, request

from api_server.schemas.common import error_response
from config.constants import DEFAULT_RATE_LIMIT_PER_MINUTE

# 每隔多少次請求執行一次全域過期 key 清理
_EVICTION_INTERVAL = 200


def register_rate_limit(app: Quart) -> None:
    _windows: dict[str, list[float]] = defaultdict(list)
    _limit = DEFAULT_RATE_LIMIT_PER_MINUTE
    _request_counter = 0

    @app.before_request
    async def check_rate_limit():
        nonlocal _request_counter

        # Skip rate limiting for static files and non-API routes
        if not request.path.startswith("/api/"):
            return

        client_ip = request.remote_addr or "unknown"
        now = time.time()

        # Remove entries older than 60 seconds for this IP
        window = _windows.get(client_ip)
        if window:
            _windows[client_ip] = [t for t in window if now - t < 60]
        else:
            _windows[client_ip] = []
        window = _windows[client_ip]

        if len(window) >= _limit:
            return error_response(
                "RATE_LIMIT_EXCEEDED",
                "Too many requests. Please try again later.",
                request_id=getattr(request, "request_id", ""),
                status_code=429,
            )

        window.append(now)

        # 定期清理過期的 IP key，防止記憶體無限膨脹
        _request_counter += 1
        if _request_counter >= _EVICTION_INTERVAL:
            _request_counter = 0
            stale_keys = [
                ip for ip, timestamps in _windows.items()
                if not timestamps or now - timestamps[-1] >= 60
            ]
            for ip in stale_keys:
                del _windows[ip]
