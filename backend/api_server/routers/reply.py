"""回复教练路由模块，分析聊天记录并生成回复建议。"""

import structlog
from quart import Blueprint, current_app, g, request

from api_server.schemas.common import success_response
from api_server.schemas.reply import ReplyAnalyzeRequest

logger = structlog.get_logger()

bp = Blueprint("reply", __name__, url_prefix="/reply")


@bp.route("/analyze", methods=["POST"])
async def analyze():
    """分析聊天内容或截图，生成智能回复建议。

    Request: {"chat_text": str|null, "screenshot_base64": str|null, "language": str, ...}
    Response: {"success": true, "data": {回复分析结果}}
    """
    request_id = g.request_id
    body = await request.get_json(force=True)
    req = ReplyAnalyzeRequest(**body)

    service = current_app.config["reply_service"]
    result = await service.analyze(req.to_domain_model(), request_id)
    return success_response(result.to_dict(), request_id)
