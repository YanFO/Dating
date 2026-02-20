from dataclasses import asdict

from quart import Blueprint, current_app, g, request

from api_server.schemas.common import error_response, success_response
from api_server.schemas.jobs import JobCreateRequest

bp = Blueprint("jobs", __name__, url_prefix="/jobs")


@bp.route("", methods=["POST"])
async def create_job():
    request_id = g.request_id
    try:
        body = await request.get_json(force=True)
        req = JobCreateRequest(**body)
    except Exception as e:
        return error_response("VALIDATION_ERROR", str(e), request_id, 422)

    service = current_app.config.get("job_service")
    if not service:
        return error_response("NOT_AVAILABLE", "Job service not configured", request_id, 503)

    job = await service.create_job(req.job_type, req.payload)
    return success_response(asdict(job), request_id, 201)


@bp.route("/<job_id>", methods=["GET"])
async def get_job(job_id: str):
    request_id = g.request_id
    service = current_app.config.get("job_service")
    if not service:
        return error_response("NOT_AVAILABLE", "Job service not configured", request_id, 503)

    job = await service.get_job(job_id)
    if not job:
        return error_response("NOT_FOUND", f"Job {job_id} not found", request_id, 404)

    return success_response(asdict(job), request_id)
