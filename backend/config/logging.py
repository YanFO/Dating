"""日志配置模块，设置 structlog 结构化日志与敏感信息脱敏。"""

import logging
import structlog


SENSITIVE_KEYS = {"key", "token", "password", "secret", "authorization", "api_key"}


def _redact_sensitive(_, __, event_dict):
    """structlog 处理器：对日志中包含敏感关键词的字段进行脱敏处理。"""
    for key in list(event_dict.keys()):
        if any(s in key.lower() for s in SENSITIVE_KEYS):
            val = event_dict[key]
            if isinstance(val, str) and len(val) > 8:
                event_dict[key] = val[:4] + "****" + val[-4:]
    return event_dict


def setup_logging(settings):
    """根据配置初始化 structlog 日志系统，设置日志级别与输出格式。"""
    log_level = getattr(logging, settings.LOG_LEVEL.upper(), logging.INFO)

    structlog.configure(
        processors=[
            structlog.contextvars.merge_contextvars,
            structlog.stdlib.add_log_level,
            structlog.stdlib.add_logger_name,
            structlog.processors.TimeStamper(fmt="iso"),
            _redact_sensitive,
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.JSONRenderer(),
        ],
        wrapper_class=structlog.stdlib.BoundLogger,
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        cache_logger_on_first_use=True,
    )

    logging.basicConfig(format="%(message)s", level=log_level)
