import structlog

logger = structlog.get_logger()


class MetricsCollector:
    def record_latency(self, operation: str, duration_ms: float) -> None:
        logger.info("metric_latency", operation=operation, duration_ms=duration_ms)

    def increment_counter(self, name: str, value: int = 1) -> None:
        logger.info("metric_counter", name=name, value=value)
