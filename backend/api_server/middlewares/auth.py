from quart import Quart, g, request

from services.auth_service import verify_request


def register_auth(app: Quart) -> None:
    @app.before_request
    async def authenticate():
        g.auth = await verify_request(dict(request.headers))
