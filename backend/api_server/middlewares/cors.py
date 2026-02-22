from quart import Quart, request, Response


def configure_cors(app: Quart, settings) -> None:
    origins = settings.CORS_ORIGINS

    @app.before_request
    async def handle_preflight():
        """Immediately respond to CORS preflight (OPTIONS) requests."""
        if request.method == "OPTIONS":
            resp = Response("", status=204)
            if origins == "*":
                resp.headers["Access-Control-Allow-Origin"] = "*"
            else:
                origin = request.headers.get("Origin", "")
                allowed = [o.strip() for o in origins.split(",")]
                if origin in allowed:
                    resp.headers["Access-Control-Allow-Origin"] = origin
            resp.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
            resp.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization, X-Request-ID"
            resp.headers["Access-Control-Max-Age"] = "3600"
            return resp

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
