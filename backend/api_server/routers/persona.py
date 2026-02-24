"""Persona HTTP 路由

提供數位人格（AI Clone）的設定讀取、語調更新、沙盒改寫端點。
對應 Flutter Profile 頁的語調滑桿與沙盒測試功能。

端點：
- GET    /api/persona          → 取得人格設定
- PUT    /api/persona/tone     → 更新語調滑桿
- POST   /api/persona/sandbox  → 沙盒訊息改寫（呼叫 LLM）
"""

import structlog
from quart import Blueprint, current_app, g, request

from api_server.schemas.common import success_response
from api_server.schemas.persona import SandboxRequest, ToneUpdateRequest

logger = structlog.get_logger()

bp = Blueprint("persona", __name__, url_prefix="/persona")


@bp.route("", methods=["GET"])
async def get_persona():
    """取得用戶人格設定

    Response 200:
        {
            "success": true,
            "request_id": "...",
            "data": {
                "user_id": "...",
                "sync_pct": 0.0,
                "emoji_usage": 50.0,
                "sentence_length": 50.0,
                "colloquialism": 50.0
            }
        }
    """
    request_id = g.request_id
    service = current_app.config["persona_service"]
    # 取得用戶人格設定（若不存在會自動建立預設值）
    persona = await service.get_persona(g.auth.user_id, request_id)
    return success_response(persona.to_dict(), request_id)


@bp.route("/tone", methods=["PUT"])
async def update_tone():
    """更新用戶語調設定

    Request Body:
        {
            "emoji_usage": 70.0,
            "sentence_length": 30.0,
            "colloquialism": 80.0
        }

    Response 200:
        {
            "success": true,
            "request_id": "...",
            "data": {
                "user_id": "...",
                "sync_pct": 0.0,
                "emoji_usage": 70.0,
                "sentence_length": 30.0,
                "colloquialism": 80.0
            }
        }
    """
    request_id = g.request_id
    body = await request.get_json(force=True)
    req = ToneUpdateRequest(**body)

    service = current_app.config["persona_service"]
    # 更新三個語調滑桿的值
    persona = await service.update_tone(
        user_id=g.auth.user_id,
        emoji_usage=req.emoji_usage,
        sentence_length=req.sentence_length,
        colloquialism=req.colloquialism,
        request_id=request_id,
    )
    return success_response(persona.to_dict(), request_id)


@bp.route("/sandbox", methods=["POST"])
async def sandbox_rewrite():
    """沙盒訊息改寫

    使用 LLM 根據用戶語調設定改寫輸入訊息。

    Request Body:
        { "text": "你今晚想吃什麼？" }

    Response 200:
        {
            "success": true,
            "request_id": "...",
            "data": {
                "original": "你今晚想吃什麼？",
                "rewritten": "Ay 今晚吃啥？有點餓了 ngl 🍕"
            }
        }
    """
    request_id = g.request_id
    body = await request.get_json(force=True)
    req = SandboxRequest(**body)

    service = current_app.config["persona_service"]
    # 呼叫 LLM 改寫訊息
    result = await service.sandbox_rewrite(g.auth.user_id, req.text, request_id)
    return success_response(result.to_dict(), request_id)
