"""Insights API 回應 DTO

定義成長洞察端點的 Pydantic 模型。
此模組為唯讀端點，僅定義回應格式。

端點對應：
- GET /api/insights/skills  → 回傳 SkillScores.to_dict()
- GET /api/insights/reports → 回傳 list[DateReport.to_dict()]
"""

# Insights 端點目前為唯讀，無需定義 request schema。
# Response 直接使用 modules/insights/models.py 的 to_dict() 輸出，
# 經由 api_server/schemas/common.py 的 success_response() 封裝。
#
# Response 格式：
#
# GET /api/insights/skills
# {
#   "success": true,
#   "request_id": "...",
#   "data": {
#     "emotional_value": 0.83,
#     "listening": 0.72,
#     "frame_control": 0.67,
#     "escalation": 0.55,
#     "empathy": 0.60,
#     "humor": 0.78
#   }
# }
#
# GET /api/insights/reports
# {
#   "success": true,
#   "request_id": "...",
#   "data": [
#     {
#       "report_id": "rpt_...",
#       "user_id": "...",
#       "score": 85,
#       "skills": { ... },
#       "good_points": ["..."],
#       "to_improve": ["..."],
#       "action_items": ["..."],
#       "created_at": "2024-..."
#     }
#   ]
# }
