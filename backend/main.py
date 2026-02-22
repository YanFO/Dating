"""HTTP + WebSocket entry point for Dating Lens backend.

Usage:
    hypercorn main:app --bind 0.0.0.0:8000
    or: python main.py
"""

from config.settings import load_settings
from config.logging import setup_logging
from config.feature_flags import FeatureFlags
from api_server.app import create_app

settings = load_settings()
setup_logging(settings)

feature_flags = FeatureFlags()
app = create_app(settings, feature_flags)


if __name__ == "__main__":
    import asyncio
    from hypercorn.asyncio import serve
    from hypercorn.config import Config

    config = Config()
    # Bind dual-stack (IPv4 + IPv6) for VS Code port forwarding compatibility
    config.bind = [f"[::]:{settings.PORT}"]
    config.accesslog = "-"

    asyncio.run(serve(app, config))
