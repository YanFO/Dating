import structlog
from quart import Quart, g

from api_server.routers.health import bp as health_bp
from api_server.routers.api_v1 import bp as api_v1_bp
from api_server.schemas.common import error_response

logger = structlog.get_logger()


def register_http_routes(app: Quart) -> None:
    app.register_blueprint(health_bp)
    app.register_blueprint(api_v1_bp)

    @app.errorhandler(404)
    async def not_found(e):
        request_id = getattr(g, "request_id", "")
        return error_response("NOT_FOUND", "Resource not found", request_id, 404)

    @app.errorhandler(405)
    async def method_not_allowed(e):
        request_id = getattr(g, "request_id", "")
        return error_response("METHOD_NOT_ALLOWED", "Method not allowed", request_id, 405)

    @app.errorhandler(500)
    async def internal_error(e):
        request_id = getattr(g, "request_id", "")
        logger.error("unhandled_error", error=str(e), request_id=request_id)
        return error_response("INTERNAL_ERROR", "Internal server error", request_id, 500)
