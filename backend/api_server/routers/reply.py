import structlog
from pydantic import ValidationError
from quart import Blueprint, current_app, g, request

from api_server.schemas.common import error_response, success_response
from api_server.schemas.reply import ReplyAnalyzeRequest
from modules.reply.errors import ChatAnalysisFailed, NoInputProvided, ReplyError

logger = structlog.get_logger()

bp = Blueprint("reply", __name__, url_prefix="/reply")


@bp.route("/analyze", methods=["POST"])
async def analyze():
    request_id = g.request_id
    try:
        body = await request.get_json(force=True)
        req = ReplyAnalyzeRequest(**body)
    except (ValidationError, TypeError, Exception) as e:
        return error_response("VALIDATION_ERROR", str(e), request_id, 422)

    service = current_app.config["reply_service"]
    try:
        result = await service.analyze(req.to_domain_model(), request_id)
        return success_response(result.to_dict(), request_id)
    except NoInputProvided as e:
        return error_response("INVALID_INPUT", str(e), request_id, 400)
    except ReplyError as e:
        logger.error("reply_analysis_failed", error=str(e), request_id=request_id)
        return error_response("ANALYSIS_FAILED", "Analysis service unavailable", request_id, 502)
