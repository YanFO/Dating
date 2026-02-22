"""Match HTTP 路由

提供約會管線（Active Pipeline）的 CRUD 端點。
對應 Flutter Home 頁的水平滾動 Match 卡片列表。

端點：
- GET    /api/matches             → 列出所有 matches
- POST   /api/matches             → 新增 match（回傳 201）
- PUT    /api/matches/<match_id>  → 更新 match
- DELETE /api/matches/<match_id>  → 刪除 match（回傳 204）
"""

import structlog
from quart import Blueprint, current_app, g, request

from api_server.schemas.common import error_response, success_response
from api_server.schemas.match import MatchCreateRequest, MatchUpdateRequest
from modules.match.errors import MatchNotFound

logger = structlog.get_logger()

bp = Blueprint("match", __name__, url_prefix="/matches")

# Phase 1 無認證，所有請求使用預設用戶 ID
DEFAULT_USER_ID = "anonymous"


@bp.route("", methods=["GET"])
async def list_matches():
    """列出用戶所有 match 記錄

    Response 200:
        {
            "success": true,
            "request_id": "...",
            "data": [ { "match_id", "name", "context_tag", "status", "created_at", "updated_at" } ]
        }
    """
    request_id = g.request_id
    service = current_app.config["match_service"]
    # 取得該用戶的所有 match 記錄
    results = await service.list_matches(DEFAULT_USER_ID, request_id)
    return success_response([m.to_dict() for m in results], request_id)


@bp.route("", methods=["POST"])
async def create_match():
    """新增一筆 match

    Request Body:
        { "name": "Elena", "context_tag": "Art Gallery" }

    Response 201:
        {
            "success": true,
            "request_id": "...",
            "data": { "match_id", "name", "context_tag", "status", "created_at", "updated_at" }
        }
    """
    request_id = g.request_id
    body = await request.get_json(force=True)
    req = MatchCreateRequest(**body)

    service = current_app.config["match_service"]
    # 建立新的 match 記錄
    record = await service.create_match(
        user_id=DEFAULT_USER_ID,
        name=req.name,
        context_tag=req.context_tag,
        request_id=request_id,
    )
    return success_response(record.to_dict(), request_id, status_code=201)


@bp.route("/<match_id>", methods=["PUT"])
async def update_match(match_id: str):
    """更新指定 match 記錄

    Path Params:
        match_id (str): 要更新的 match ID

    Request Body（選填欄位）:
        { "name": "Elena V2", "context_tag": "Museum", "status": "archived" }

    Response 200:
        {
            "success": true,
            "request_id": "...",
            "data": { "match_id", "name", "context_tag", "status", "created_at", "updated_at" }
        }

    Response 404:
        { "success": false, "error": { "code": "NOT_FOUND", "message": "..." } }
    """
    request_id = g.request_id
    body = await request.get_json(force=True)
    req = MatchUpdateRequest(**body)

    service = current_app.config["match_service"]
    try:
        # 更新 match 記錄（僅更新有提供的欄位）
        record = await service.update_match(
            user_id=DEFAULT_USER_ID,
            match_id=match_id,
            request_id=request_id,
            name=req.name,
            context_tag=req.context_tag,
            status=req.status,
        )
        return success_response(record.to_dict(), request_id)
    except MatchNotFound:
        return error_response("NOT_FOUND", f"Match {match_id} not found", request_id, 404)


@bp.route("/<match_id>", methods=["DELETE"])
async def delete_match(match_id: str):
    """刪除指定 match 記錄

    Path Params:
        match_id (str): 要刪除的 match ID

    Response 204: 無內容

    Response 404:
        { "success": false, "error": { "code": "NOT_FOUND", "message": "..." } }
    """
    request_id = g.request_id
    service = current_app.config["match_service"]
    try:
        # 從記憶體中刪除 match 記錄
        await service.delete_match(DEFAULT_USER_ID, match_id, request_id)
        return "", 204
    except MatchNotFound:
        return error_response("NOT_FOUND", f"Match {match_id} not found", request_id, 404)
