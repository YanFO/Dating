"""通用响应模型模块，定义统一的 API 响应信封格式。"""

from dataclasses import dataclass, asdict
from typing import Any, Optional

from quart import jsonify


@dataclass
class ErrorDetail:
    """错误详情数据类，包含错误码和错误信息。"""

    code: str
    message: str
    details: Optional[dict] = None


@dataclass
class ResponseEnvelope:
    """统一响应信封，封装成功/失败状态、请求 ID、数据或错误信息。"""

    success: bool
    request_id: str
    data: Optional[Any] = None
    error: Optional[ErrorDetail] = None


def success_response(data: Any, request_id: str, status_code: int = 200):
    """构建成功响应，将数据包装在标准信封中返回。"""
    envelope = ResponseEnvelope(success=True, request_id=request_id, data=data)
    return jsonify(asdict(envelope)), status_code


def error_response(
    code: str, message: str, request_id: str, status_code: int = 400
):
    """构建错误响应，将错误码和信息包装在标准信封中返回。"""
    envelope = ResponseEnvelope(
        success=False,
        request_id=request_id,
        error=ErrorDetail(code=code, message=message),
    )
    return jsonify(asdict(envelope)), status_code
