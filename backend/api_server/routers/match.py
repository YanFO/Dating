"""Match HTTP 路由

提供約會管線（Active Pipeline）與記憶檔案的 CRUD 端點。

端點：
- GET    /api/matches                          → 列出所有 matches
- POST   /api/matches                          → 新增 match（回傳 201）
- PUT    /api/matches/<match_id>               → 更新 match
- DELETE /api/matches/<match_id>               → 刪除 match（回傳 204）
- GET    /api/matches/<match_id>/memory        → 取得 memory profile
- PUT    /api/matches/<match_id>/memory        → 建立/更新 memory profile
- DELETE /api/matches/<match_id>/memory        → 刪除 memory profile
"""

import structlog
from quart import Blueprint, current_app, g, request

from api_server.schemas.common import error_response, success_response
from api_server.schemas.match import ChatImportRequest, MatchCreateRequest, MatchUpdateRequest, MemoryUpsertRequest
from modules.match.errors import MatchNotFound, MemoryNotFound

logger = structlog.get_logger()

bp = Blueprint("match", __name__, url_prefix="/matches")


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
    results = await service.list_matches(g.auth.user_id, request_id)
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
        user_id=g.auth.user_id,
        name=req.name,
        context_tag=req.context_tag,
        request_id=request_id,
    )
    return success_response(record.to_dict(), request_id, status_code=201)


@bp.route("/import-chat", methods=["POST"])
async def import_chat():
    """上傳聊天記錄，透過 LLM 分析後自動建立 match + memory

    支援單張或多張圖片上傳。多張圖片會由 LLM 透過頭貼與聊天室名稱
    判斷不同對象，各自建立獨立的 match。

    Request Body (JSON):
        { "chat_text": "聊天文字..." }
    Or multipart form-data:
        image: 單張聊天截圖（向下相容）
        images: 多張聊天截圖

    Response 201:
        {
            "success": true,
            "data": {
                "matches": [
                    {
                        "match": { match 記錄 },
                        "memory": { memory profile },
                        "relationship_stage": "early/flirting/couple"
                    }
                ]
            }
        }
    """
    import base64 as b64mod

    request_id = g.request_id
    service = current_app.config["match_service"]

    chat_text = None
    images_base64: list[str] = []

    content_type = request.content_type or ""
    if "multipart" in content_type:
        files = await request.files
        form = await request.form
        chat_text = form.get("chat_text")

        # 多圖: field name "images"
        img_list = files.getlist("images")
        for img_file in img_list:
            image_bytes = img_file.read()
            images_base64.append(b64mod.b64encode(image_bytes).decode("utf-8"))

        # 向下相容: 單圖 field name "image"
        if not images_base64:
            img_file = files.get("image")
            if img_file:
                image_bytes = img_file.read()
                images_base64.append(b64mod.b64encode(image_bytes).decode("utf-8"))
    else:
        body = await request.get_json(force=True)
        req = ChatImportRequest(**body)
        chat_text = req.chat_text

    if not chat_text and not images_base64:
        return error_response(
            "VALIDATION_ERROR",
            "At least chat_text or image is required",
            request_id,
            400,
        )

    try:
        if len(images_base64) > 1:
            # 多圖：一次送 LLM 分析，自動辨識不同對象
            results = await service.import_chat_multi(
                user_id=g.auth.user_id,
                request_id=request_id,
                images_base64=images_base64,
                chat_text=chat_text,
            )
        elif len(images_base64) == 1:
            # 單圖：使用原有邏輯
            result = await service.import_chat(
                user_id=g.auth.user_id,
                request_id=request_id,
                chat_text=chat_text,
                image_base64=images_base64[0],
            )
            results = [result]
        else:
            # 純文字
            result = await service.import_chat(
                user_id=g.auth.user_id,
                request_id=request_id,
                chat_text=chat_text,
            )
            results = [result]

        return success_response(
            {
                "matches": [
                    {
                        "match": r.match.to_dict(),
                        "memory": r.memory.to_dict(),
                        "relationship_stage": r.relationship_stage,
                    }
                    for r in results
                ],
            },
            request_id,
            status_code=201,
        )
    except Exception as e:
        logger.error("import_chat_failed", error=str(e), request_id=request_id)
        return error_response("IMPORT_FAILED", str(e), request_id, 500)


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
            user_id=g.auth.user_id,
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
        await service.delete_match(g.auth.user_id, match_id, request_id)
        return "", 204
    except MatchNotFound:
        return error_response("NOT_FOUND", f"Match {match_id} not found", request_id, 404)


# ─── Memory 端點 ──────────────────────────────────

@bp.route("/<match_id>/memory", methods=["GET"])
async def get_memory(match_id: str):
    """取得 match 的 memory profile

    Response 200:
        { "success": true, "data": { memory profile fields... } }
    """
    request_id = g.request_id
    service = current_app.config["match_service"]
    try:
        profile = await service.get_memory(g.auth.user_id, match_id, request_id)
        return success_response(profile.to_dict(), request_id)
    except MatchNotFound:
        return error_response("NOT_FOUND", f"Match {match_id} not found", request_id, 404)


@bp.route("/<match_id>/memory", methods=["PUT"])
async def upsert_memory(match_id: str):
    """建立或更新 match 的 memory profile（部分更新）

    Request Body（所有欄位選填）:
        { "birthday": "03-15", "favorite_food": ["壽司"] }

    Response 200:
        { "success": true, "data": { memory profile fields... } }
    """
    request_id = g.request_id
    body = await request.get_json(force=True)
    req = MemoryUpsertRequest(**body)

    service = current_app.config["match_service"]
    try:
        profile = await service.upsert_memory(
            g.auth.user_id, match_id, req.to_update_dict(), request_id,
        )
        return success_response(profile.to_dict(), request_id)
    except MatchNotFound:
        return error_response("NOT_FOUND", f"Match {match_id} not found", request_id, 404)


@bp.route("/<match_id>/memory", methods=["DELETE"])
async def delete_memory(match_id: str):
    """刪除 match 的 memory profile

    Response 204: 無內容
    """
    request_id = g.request_id
    service = current_app.config["match_service"]
    try:
        await service.delete_memory(g.auth.user_id, match_id, request_id)
        return "", 204
    except MatchNotFound:
        return error_response("NOT_FOUND", f"Match {match_id} not found", request_id, 404)
    except MemoryNotFound:
        return error_response("NOT_FOUND", f"Memory for match {match_id} not found", request_id, 404)
