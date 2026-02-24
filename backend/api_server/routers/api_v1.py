"""API 路由聚合器

將所有功能模組的 Blueprint 註冊到統一的 /api 前綴下。
此檔案為 transport 層的接線邏輯，不包含任何業務邏輯。
"""

from quart import Blueprint

from api_server.routers.auth_router import bp as auth_bp
from api_server.routers.icebreaker import bp as icebreaker_bp
from api_server.routers.insights import bp as insights_bp
from api_server.routers.jobs import bp as jobs_bp
from api_server.routers.love_coach import bp as love_coach_bp
from api_server.routers.match import bp as match_bp
from api_server.routers.persona import bp as persona_bp
from api_server.routers.reply import bp as reply_bp
from config.constants import API_PREFIX

bp = Blueprint("api", __name__, url_prefix=API_PREFIX)

# 註冊各功能模組路由
bp.register_blueprint(auth_bp)
bp.register_blueprint(icebreaker_bp)
bp.register_blueprint(reply_bp)
bp.register_blueprint(jobs_bp)
bp.register_blueprint(match_bp)
bp.register_blueprint(persona_bp)
bp.register_blueprint(insights_bp)
bp.register_blueprint(love_coach_bp)
