import time
from collections import defaultdict

from quart import Quart, request

from api_server.schemas.common import error_response
from config.constants import DEFAULT_RATE_LIMIT_PER_MINUTE


def register_rate_limit(app: Quart) -> None:
    _windows: dict[str, list[float]] = defaultdict(list)
    _limit = DEFAULT_RATE_LIMIT_PER_MINUTE

    @app.before_request
    async def check_rate_limit():
        client_ip = request.remote_addr or "unknown"
        now = time.time()
        window = _windows[client_ip]

        # Remove entries older than 60 seconds
        _windows[client_ip] = [t for t in window if now - t < 60]
        window = _windows[client_ip]

        if len(window) >= _limit:
            return error_response(
                "RATE_LIMIT_EXCEEDED",
                "Too many requests. Please try again later.",
                request_id=getattr(request, "request_id", ""),
                status_code=429,
            )

        window.append(now)
