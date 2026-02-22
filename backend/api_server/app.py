"""应用工厂模块，创建并配置 Quart 应用实例。"""

from quart import Quart

from api_server.http import register_http_routes
from api_server.lifecycle import register_lifecycle
from api_server.middlewares.auth import register_auth
from api_server.middlewares.cors import configure_cors
from api_server.middlewares.rate_limit import register_rate_limit
from api_server.middlewares.security_headers import register_security_headers
from api_server.middlewares.tracing import register_tracing
from api_server.websocket import register_websocket_routes
from config.feature_flags import FeatureFlags


def create_app(settings, feature_flags: FeatureFlags = None) -> Quart:
    """创建 Quart 应用，注册中间件、路由和生命周期钩子。"""
    app = Quart(__name__)
    app.config["SETTINGS"] = settings
    app.config["FEATURE_FLAGS"] = feature_flags or FeatureFlags()
    app.config["MAX_CONTENT_LENGTH"] = 16 * 1024 * 1024  # 16MB

    # Middleware registration order matters:
    # 1. tracing (request_id) first
    # 2. CORS (must be before auth so OPTIONS preflight is handled)
    # 3. auth
    # 4. rate limit
    register_tracing(app)
    configure_cors(app, settings)
    register_auth(app)
    register_rate_limit(app)
    register_security_headers(app)

    # Routes
    register_http_routes(app)
    register_websocket_routes(app)

    # Lifecycle
    register_lifecycle(app)

    return app
