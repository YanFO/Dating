import structlog
from pydantic import ValidationError
from quart import Blueprint, current_app, g, request

from api_server.schemas.common import error_response, success_response
from api_server.schemas.icebreaker import IcebreakerAnalyzeRequest
from modules.icebreaker.errors import IcebreakerError, InvalidInputError

logger = structlog.get_logger()

bp = Blueprint("icebreaker", __name__, url_prefix="/icebreaker")


@bp.route("/analyze", methods=["POST"])
async def analyze():
    request_id = g.request_id
    try:
        body = await request.get_json(force=True)
        req = IcebreakerAnalyzeRequest(**body)
    except (ValidationError, TypeError, Exception) as e:
        return error_response("VALIDATION_ERROR", str(e), request_id, 422)

    service = current_app.config["icebreaker_service"]
    try:
        result = await service.analyze(req.to_domain_model(), request_id)
        return success_response(result.to_dict(), request_id)
    except InvalidInputError as e:
        return error_response("INVALID_INPUT", str(e), request_id, 400)
    except IcebreakerError as e:
        logger.error("icebreaker_analysis_failed", error=str(e), request_id=request_id)
        return error_response("ANALYSIS_FAILED", "Analysis service unavailable", request_id, 502)
