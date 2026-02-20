from quart import Quart, request


def configure_cors(app: Quart, settings) -> None:
    origins = settings.CORS_ORIGINS

    @app.after_request
    async def add_cors_headers(response):
        if origins == "*":
            response.headers["Access-Control-Allow-Origin"] = "*"
        else:
            origin = request.headers.get("Origin", "")
            allowed = [o.strip() for o in origins.split(",")]
            if origin in allowed:
                response.headers["Access-Control-Allow-Origin"] = origin

        response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
        response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization, X-Request-ID"
        response.headers["Access-Control-Max-Age"] = "3600"
        return response
