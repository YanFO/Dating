"""HTTP 路由註冊與全域錯誤處理

將所有 Blueprint 註冊到 Quart app，並設定統一的錯誤回應格式。
包含 Pydantic ValidationError 的攔截，回傳 422 而非 500。
"""

from pathlib import Path

import structlog
from pydantic import ValidationError
from quart import Quart, g, send_from_directory, send_file

from api_server.routers.health import bp as health_bp
from api_server.routers.api_v1 import bp as api_bp
from api_server.schemas.common import error_response

logger = structlog.get_logger()

# Flutter Web build directory
_FLUTTER_WEB_DIR = Path(__file__).resolve().parent.parent.parent / "flutter" / "build" / "web"


def register_http_routes(app: Quart) -> None:
    """註冊所有 HTTP 路由與全域錯誤處理器"""
    app.register_blueprint(health_bp)
    app.register_blueprint(api_bp)

    # Files that must never be cached (SW + bootstrap)
    _NO_CACHE_FILES = {"flutter_service_worker.js", "index.html", "main.dart.js", "version.json"}

    # Serve Flutter Web static files from the same port
    @app.route("/", defaults={"path": ""})
    @app.route("/<path:path>")
    async def serve_flutter(path: str):
        """Serve Flutter Web app — all non-API routes fall through here."""
        if _FLUTTER_WEB_DIR.exists():
            file_path = _FLUTTER_WEB_DIR / path
            if file_path.is_file():
                response = await send_from_directory(str(_FLUTTER_WEB_DIR), path)
                # Prevent caching for SW and bootstrap files
                if Path(path).name in _NO_CACHE_FILES:
                    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
                    response.headers["Pragma"] = "no-cache"
                    response.headers["Expires"] = "0"
                return response
            # SPA fallback: return index.html for client-side routing
            index = _FLUTTER_WEB_DIR / "index.html"
            if index.is_file():
                response = await send_file(str(index))
                response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
                return response
        return "Flutter build not found. Run: cd flutter && flutter build web", 404

    @app.errorhandler(ValidationError)
    async def validation_error(e: ValidationError):
        """攔截 Pydantic 驗證錯誤，回傳 422 與具體錯誤訊息"""
        request_id = getattr(g, "request_id", "")
        # 取第一個錯誤的訊息作為回應
        first_error = e.errors()[0] if e.errors() else {}
        field = ".".join(str(loc) for loc in first_error.get("loc", []))
        msg = first_error.get("msg", "Validation error")
        message = f"{field}: {msg}" if field else msg
        return error_response("VALIDATION_ERROR", message, request_id, 422)

    @app.errorhandler(404)
    async def not_found(e):
        """處理 404 路由不存在"""
        request_id = getattr(g, "request_id", "")
        return error_response("NOT_FOUND", "Resource not found", request_id, 404)

    @app.errorhandler(405)
    async def method_not_allowed(e):
        """處理 405 方法不允許"""
        request_id = getattr(g, "request_id", "")
        return error_response("METHOD_NOT_ALLOWED", "Method not allowed", request_id, 405)

    @app.errorhandler(500)
    async def internal_error(e):
        """處理 500 內部錯誤（不外洩 stack trace）"""
        request_id = getattr(g, "request_id", "")
        logger.error("unhandled_error", error=str(e), request_id=request_id)
        return error_response("INTERNAL_ERROR", "Internal server error", request_id, 500)
