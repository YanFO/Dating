"""认证服务模块，提供请求与 WebSocket 的身份验证功能。"""

from dataclasses import dataclass
from typing import Optional

import structlog

logger = structlog.get_logger()


@dataclass
class AuthContext:
    """认证上下文，包含用户 ID、角色及认证状态。"""
    user_id: str
    role: str = "user"
    is_authenticated: bool = True


async def verify_request(headers: dict) -> AuthContext:
    """验证 HTTP 请求的身份信息。
    Phase 1 阶段为空操作，始终返回匿名用户；Phase 4 将替换为 JWT 验证。
    """
    return AuthContext(user_id="anonymous", role="user", is_authenticated=True)


async def verify_ws_token(token: Optional[str]) -> AuthContext:
    """验证 WebSocket 连接令牌。Phase 1 阶段为空操作。"""
    return AuthContext(user_id="anonymous", role="user", is_authenticated=True)
