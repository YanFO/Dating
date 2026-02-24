"""破冰开场白路由模块，处理场景分析并生成搭讪建议。"""

import structlog
from quart import Blueprint, current_app, g, request

from api_server.schemas.common import success_response
from api_server.schemas.icebreaker import IcebreakerAnalyzeRequest

logger = structlog.get_logger()

bp = Blueprint("icebreaker", __name__, url_prefix="/icebreaker")


@bp.route("/analyze", methods=["POST"])
async def analyze():
    """分析场景图片或描述，生成破冰开场白建议。

    Request: {"scene_description": str, "image_base64": str|null, "language": str}
    Response: {"success": true, "data": {分析结果}}
    """
    request_id = g.request_id
    body = await request.get_json(force=True)
    req = IcebreakerAnalyzeRequest(**body)

    service = current_app.config["icebreaker_service"]
    result = await service.analyze(req.to_domain_model(), request_id, user_id=g.auth.user_id)
    return success_response(result.to_dict(), request_id)
