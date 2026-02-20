from dataclasses import dataclass
from typing import Optional

import structlog

logger = structlog.get_logger()


@dataclass
class AuthContext:
    user_id: str
    role: str = "user"
    is_authenticated: bool = True


async def verify_request(headers: dict) -> AuthContext:
    """Phase 1: No-op auth that always succeeds.
    Will be replaced with JWT validation in Phase 4.
    """
    return AuthContext(user_id="anonymous", role="user", is_authenticated=True)


async def verify_ws_token(token: Optional[str]) -> AuthContext:
    """Phase 1: No-op WebSocket auth."""
    return AuthContext(user_id="anonymous", role="user", is_authenticated=True)
