"""健康检查路由模块，提供服务存活和就绪探针端点。"""

from sqlalchemy import text
from quart import Blueprint, current_app, g

from api_server.schemas.common import success_response
from utils.time import format_iso, utcnow

bp = Blueprint("health", __name__)


@bp.route("/health", methods=["GET"])
async def health():
    """存活探针：返回服务运行状态。

    Response: {"success": true, "data": {"status": "ok", "timestamp": "..."}}
    """
    request_id = getattr(g, "request_id", "")
    return success_response(
        {"status": "ok", "timestamp": format_iso(utcnow())},
        request_id,
    )


@bp.route("/ready", methods=["GET"])
async def ready():
    """就绪探针：检查 PostgreSQL 和 MongoDB 连接状态。

    Response: {"success": true, "data": {"status": "ready", "checks": {...}}}
    """
    request_id = getattr(g, "request_id", "")
    checks = {}

    # Check PostgreSQL
    pg_session_factory = current_app.config.get("pg_session_factory")
    if pg_session_factory:
        async with pg_session_factory() as session:
            await session.execute(text("SELECT 1"))
        checks["postgres"] = "ok"

    # Check MongoDB
    mongo_db = current_app.config.get("mongo_db")
    if mongo_db is not None:
        await mongo_db.command("ping")
        checks["mongodb"] = "ok"

    return success_response(
        {"status": "ready", "timestamp": format_iso(utcnow()), "checks": checks},
        request_id,
    )
