"""Insights HTTP 路由

提供成長雷達圖數據、約會報告及語音教練對話紀錄端點。
對應 Flutter Insights 頁的雷達圖、Post-Date Report 與語音教練分析。

端點：
- GET /api/insights/skills           → 取得最新 6 維技能分數
- GET /api/insights/reports          → 列出所有約會報告
- GET /api/insights/voice-coach-logs → 列出語音教練對話紀錄
"""

import structlog
from quart import Blueprint, current_app, g

from api_server.schemas.common import success_response

logger = structlog.get_logger()

bp = Blueprint("insights", __name__, url_prefix="/insights")

# Phase 1 無認證，所有請求使用預設用戶 ID
DEFAULT_USER_ID = "anonymous"


@bp.route("/skills", methods=["GET"])
async def get_skills():
    """取得用戶最新的 6 維技能分數（雷達圖數據）

    Response 200:
        {
            "success": true,
            "request_id": "...",
            "data": {
                "emotional_value": 0.83,
                "listening": 0.72,
                "frame_control": 0.67,
                "escalation": 0.55,
                "empathy": 0.60,
                "humor": 0.78
            }
        }
    """
    request_id = g.request_id
    service = current_app.config["insights_service"]
    # 查詢該用戶最新的技能分數
    skills = await service.get_latest_skills(DEFAULT_USER_ID, request_id)
    return success_response(skills.to_dict(), request_id)


@bp.route("/reports", methods=["GET"])
async def list_reports():
    """列出用戶所有約會報告

    Response 200:
        {
            "success": true,
            "request_id": "...",
            "data": [
                {
                    "report_id": "rpt_...",
                    "user_id": "anonymous",
                    "score": 85,
                    "skills": {
                        "emotional_value": 0.83,
                        "listening": 0.72,
                        "frame_control": 0.67,
                        "escalation": 0.55,
                        "empathy": 0.60,
                        "humor": 0.78
                    },
                    "good_points": ["保持了良好的眼神交流", "有效運用了回呼幽默"],
                    "to_improve": ["在對方說話時打斷了 3 次"],
                    "action_items": ["練習主動傾聽技巧"],
                    "created_at": "2024-..."
                }
            ]
        }
    """
    request_id = g.request_id
    service = current_app.config["insights_service"]
    # 列出該用戶所有約會報告
    reports = await service.list_reports(DEFAULT_USER_ID, request_id)
    return success_response([r.to_dict() for r in reports], request_id)


@bp.route("/voice-coach-logs", methods=["GET"])
async def list_voice_coach_logs():
    """列出用戶語音教練對話紀錄

    Response 200:
        {
            "success": true,
            "request_id": "...",
            "data": [
                {
                    "log_id": "...",
                    "session_id": "...",
                    "input_transcripts": ["你好啊", "最近怎麼樣"],
                    "coach_transcripts": ["試著問她興趣..."],
                    "coaching_updates": [
                        {
                            "emotion": "開心",
                            "emotion_detail": "...",
                            "suggestions": ["..."],
                            "direction": "..."
                        }
                    ],
                    "duration_ms": 120000,
                    "created_at": "2024-..."
                }
            ]
        }
    """
    request_id = g.request_id
    service = current_app.config["insights_service"]
    # 列出該用戶所有語音教練對話紀錄
    logs = await service.list_voice_coach_logs(DEFAULT_USER_ID, request_id)
    return success_response([log.to_dict() for log in logs], request_id)
