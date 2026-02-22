"""Love Coach 聊天路由模組

提供 SSE 串流聊天端點與對話管理 API。
遵循薄路由原則：僅負責輸入驗證、呼叫服務層、格式化輸出。

端點：
- POST /chat：SSE 串流聊天（主要功能）
- GET /conversations：列出對話摘要
- GET /conversations/<id>/messages：取得對話歷史
- DELETE /conversations/<id>：刪除對話
"""

import orjson
import structlog
from quart import Blueprint, Response, current_app, g, request

from api_server.schemas.common import error_response, success_response
from api_server.schemas.love_coach import LoveCoachChatRequestSchema
from modules.love_coach.errors import ConversationNotFoundError

logger = structlog.get_logger()

bp = Blueprint("love_coach", __name__, url_prefix="/love-coach")


# ─── SSE 串流聊天 ─────────────────────────────────

@bp.route("/chat", methods=["POST"])
async def chat():
    """Love Coach SSE 串流聊天端點。

    接收使用者訊息與可選的對話 ID，透過 Gemini 串流生成回覆。
    回應格式為 Server-Sent Events：
    - data: <text_chunk>  （逐步回傳的文字片段）
    - event: done / data: {"conversation_id": "..."}  （串流結束）
    - event: error / data: <error_message>  （發生錯誤）

    Request Body:
        message (str): 使用者訊息
        conversation_id (str, optional): 既有對話 ID
        language (str, optional): 回覆語言，預設 "zh-TW"

    Returns:
        SSE Response: text/event-stream 串流回應
    """
    request_id = g.request_id

    # 功能開關檢查
    service = current_app.config.get("love_coach_service")
    if not service:
        return error_response("SERVICE_UNAVAILABLE", "Love Coach 功能未啟用", request_id, 503)

    body = await request.get_json(force=True)
    req = LoveCoachChatRequestSchema(**body)

    # 取得對話 ID 與串流生成器
    conversation_id, stream = await service.chat_stream(
        req.to_domain_model(), request_id
    )

    async def generate():
        """SSE 事件生成器，逐步產出文字 chunk"""
        try:
            async for chunk in stream:
                # SSE 標準格式：含換行的 chunk 需拆分為多行 data:
                for line in chunk.split("\n"):
                    yield f"data: {line}\n"
                yield "\n"

            # 串流完成，回傳對話 ID 供前端持久化
            done_payload = orjson.dumps(
                {"conversation_id": conversation_id}
            ).decode()
            yield f"event: done\ndata: {done_payload}\n\n"

        except Exception as e:
            logger.error(
                "love_coach_stream_error",
                error=str(e),
                request_id=request_id,
                conversation_id=conversation_id,
            )
            # 不洩漏內部錯誤細節給客戶端
            yield "event: error\ndata: 串流回覆時發生錯誤，請稍後再試\n\n"

    return Response(
        generate(),
        content_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Request-ID": request_id,
            "X-Accel-Buffering": "no",  # 防止 Nginx 緩衝 SSE
        },
    )


# ─── 對話列表 ─────────────────────────────────────

@bp.route("/conversations", methods=["GET"])
async def list_conversations():
    """列出使用者的所有對話摘要。

    Response:
        {"success": true, "data": [{"id": str, "title": str, ...}]}
    """
    request_id = g.request_id
    service = current_app.config.get("love_coach_service")
    if not service:
        return error_response("SERVICE_UNAVAILABLE", "Love Coach 功能未啟用", request_id, 503)

    # Phase 1：使用匿名用戶 ID
    conversations = await service.get_conversations("anonymous")
    return success_response(
        [c.to_dict() for c in conversations],
        request_id,
    )


# ─── 對話歷史 ─────────────────────────────────────

@bp.route("/conversations/<conversation_id>/messages", methods=["GET"])
async def get_conversation_messages(conversation_id: str):
    """取得指定對話的所有訊息歷史。

    Path Parameters:
        conversation_id: 對話 ID

    Response:
        {"success": true, "data": [{"id": str, "role": str, "text": str, ...}]}
    """
    request_id = g.request_id
    service = current_app.config.get("love_coach_service")
    if not service:
        return error_response("SERVICE_UNAVAILABLE", "Love Coach 功能未啟用", request_id, 503)

    try:
        # Phase 1：使用匿名用戶 ID（授權檢查仍然必要）
        messages = await service.get_conversation_messages(conversation_id, "anonymous")
        return success_response(
            [m.to_dict() for m in messages],
            request_id,
        )
    except ConversationNotFoundError:
        return error_response("NOT_FOUND", "對話不存在", request_id, 404)


# ─── 刪除對話 ─────────────────────────────────────

@bp.route("/conversations/<conversation_id>", methods=["DELETE"])
async def delete_conversation(conversation_id: str):
    """刪除指定對話及其所有訊息。

    Path Parameters:
        conversation_id: 對話 ID

    Response:
        {"success": true, "data": {"deleted": true}}
    """
    request_id = g.request_id
    service = current_app.config.get("love_coach_service")
    if not service:
        return error_response("SERVICE_UNAVAILABLE", "Love Coach 功能未啟用", request_id, 503)

    try:
        # Phase 1：使用匿名用戶 ID（授權檢查仍然必要）
        await service.delete_conversation(conversation_id, "anonymous")
        return success_response({"deleted": True}, request_id)
    except ConversationNotFoundError:
        return error_response("NOT_FOUND", "對話不存在", request_id, 404)
