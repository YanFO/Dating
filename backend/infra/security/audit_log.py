from typing import Any, Optional

import structlog

from utils.time import utcnow, format_iso

logger = structlog.get_logger()


def log_audit_event(
    user_id: str,
    action: str,
    resource_id: str,
    metadata: Optional[dict[str, Any]] = None,
) -> None:
    logger.info(
        "audit_event",
        user_id=user_id,
        action=action,
        resource_id=resource_id,
        timestamp=format_iso(utcnow()),
        metadata=metadata or {},
    )
