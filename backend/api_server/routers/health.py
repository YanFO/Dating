from sqlalchemy import text
from quart import Blueprint, current_app, g

from api_server.schemas.common import success_response, error_response
from utils.time import format_iso, utcnow

bp = Blueprint("health", __name__)


@bp.route("/health", methods=["GET"])
async def health():
    request_id = getattr(g, "request_id", "")
    return success_response(
        {"status": "ok", "timestamp": format_iso(utcnow())},
        request_id,
    )


@bp.route("/ready", methods=["GET"])
async def ready():
    request_id = getattr(g, "request_id", "")
    checks = {}

    # Check PostgreSQL
    pg_session_factory = current_app.config.get("pg_session_factory")
    if pg_session_factory:
        try:
            async with pg_session_factory() as session:
                await session.execute(text("SELECT 1"))
            checks["postgres"] = "ok"
        except Exception:
            checks["postgres"] = "unavailable"
            return error_response("DB_UNAVAILABLE", "PostgreSQL not reachable", request_id, 503)

    # Check MongoDB
    mongo_db = current_app.config.get("mongo_db")
    if mongo_db is not None:
        try:
            await mongo_db.command("ping")
            checks["mongodb"] = "ok"
        except Exception:
            checks["mongodb"] = "unavailable"
            return error_response("DB_UNAVAILABLE", "MongoDB not reachable", request_id, 503)

    return success_response(
        {"status": "ready", "timestamp": format_iso(utcnow()), "checks": checks},
        request_id,
    )
