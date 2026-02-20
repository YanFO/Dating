import structlog
from quart import Quart, g, request

from services.id_service import generate_request_id
from utils.time import timestamp_ms

logger = structlog.get_logger()


def register_tracing(app: Quart) -> None:
    @app.before_request
    async def inject_request_id():
        rid = request.headers.get("X-Request-ID") or generate_request_id()
        g.request_id = rid
        g.request_start_ms = timestamp_ms()
        structlog.contextvars.bind_contextvars(request_id=rid)

    @app.after_request
    async def add_request_id_header(response):
        rid = getattr(g, "request_id", "")
        response.headers["X-Request-ID"] = rid

        start = getattr(g, "request_start_ms", None)
        if start:
            duration = timestamp_ms() - start
            logger.info(
                "request_completed",
                method=request.method,
                path=request.path,
                status=response.status_code,
                duration_ms=duration,
            )

        structlog.contextvars.unbind_contextvars("request_id")
        return response
