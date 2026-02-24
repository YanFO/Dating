"""認證服務模組，提供請求與 WebSocket 的身份驗證功能。

Phase 4: 驗證 Authorization: Bearer <sessionToken> 透過 lens_account DB。
無 token 時回退到匿名用戶（optional login）。
"""

from dataclasses import dataclass
from datetime import datetime
from typing import Optional

import structlog

logger = structlog.get_logger()


@dataclass
class AuthContext:
    """認證上下文，包含用戶 ID、角色及認證狀態。"""
    user_id: str
    role: str = "user"
    is_authenticated: bool = True


async def verify_request(headers: dict) -> AuthContext:
    """驗證 HTTP 請求的身份信息。

    從 Authorization: Bearer <sessionToken> 提取 token，
    查詢 lens_account.Session 驗證有效性。
    無 token 或驗證失敗時返回匿名用戶。
    """
    auth_header = headers.get("Authorization") or headers.get("authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        return AuthContext(user_id="anonymous", role="user", is_authenticated=False)

    session_token = auth_header[7:]  # Strip "Bearer "
    if not session_token:
        return AuthContext(user_id="anonymous", role="user", is_authenticated=False)

    try:
        from clients.auth_db_client import get_auth_db_session, _pool

        if _pool is None:
            return AuthContext(user_id="anonymous", role="user", is_authenticated=False)

        async with get_auth_db_session() as session:
            result = await session.execute(
                'SELECT u.id, s.expires '
                'FROM "Session" s JOIN "User" u ON s."userId" = u.id '
                'WHERE s."sessionToken" = :session_token',
                {"session_token": session_token},
            )
            row = result.fetchone()

            if not row:
                return AuthContext(user_id="anonymous", role="user", is_authenticated=False)

            expires = row[1]
            if expires.replace(tzinfo=None) < datetime.utcnow():
                return AuthContext(user_id="anonymous", role="user", is_authenticated=False)

            return AuthContext(user_id=row[0], role="user", is_authenticated=True)

    except Exception as e:
        logger.warning("auth_verify_failed", error=str(e))
        return AuthContext(user_id="anonymous", role="user", is_authenticated=False)


async def verify_ws_token(token: Optional[str]) -> AuthContext:
    """驗證 WebSocket 連接令牌。"""
    if not token:
        return AuthContext(user_id="anonymous", role="user", is_authenticated=False)

    try:
        from clients.auth_db_client import get_auth_db_session, _pool

        if _pool is None:
            return AuthContext(user_id="anonymous", role="user", is_authenticated=False)

        async with get_auth_db_session() as session:
            result = await session.execute(
                'SELECT u.id, s.expires '
                'FROM "Session" s JOIN "User" u ON s."userId" = u.id '
                'WHERE s."sessionToken" = :session_token',
                {"session_token": token},
            )
            row = result.fetchone()

            if not row:
                return AuthContext(user_id="anonymous", role="user", is_authenticated=False)

            expires = row[1]
            if expires.replace(tzinfo=None) < datetime.utcnow():
                return AuthContext(user_id="anonymous", role="user", is_authenticated=False)

            return AuthContext(user_id=row[0], role="user", is_authenticated=True)

    except Exception as e:
        logger.warning("ws_auth_verify_failed", error=str(e))
        return AuthContext(user_id="anonymous", role="user", is_authenticated=False)
