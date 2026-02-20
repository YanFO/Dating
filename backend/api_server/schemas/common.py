from dataclasses import dataclass, asdict
from typing import Any, Optional

from quart import jsonify


@dataclass
class ErrorDetail:
    code: str
    message: str
    details: Optional[dict] = None


@dataclass
class ResponseEnvelope:
    success: bool
    request_id: str
    data: Optional[Any] = None
    error: Optional[ErrorDetail] = None


def success_response(data: Any, request_id: str, status_code: int = 200):
    envelope = ResponseEnvelope(success=True, request_id=request_id, data=data)
    return jsonify(asdict(envelope)), status_code


def error_response(
    code: str, message: str, request_id: str, status_code: int = 400
):
    envelope = ResponseEnvelope(
        success=False,
        request_id=request_id,
        error=ErrorDetail(code=code, message=message),
    )
    return jsonify(asdict(envelope)), status_code
