import structlog

from utils.time import timestamp_ms

logger = structlog.get_logger()


class Tracer:
    def start_span(self, name: str, request_id: str = "") -> dict:
        span = {"name": name, "request_id": request_id, "start_ms": timestamp_ms()}
        logger.debug("span_start", **span)
        return span

    def end_span(self, span: dict) -> None:
        duration = timestamp_ms() - span["start_ms"]
        logger.debug("span_end", name=span["name"], duration_ms=duration)
