from quart import Blueprint

from api_server.routers.icebreaker import bp as icebreaker_bp
from api_server.routers.reply import bp as reply_bp
from api_server.routers.jobs import bp as jobs_bp

from config.constants import API_V1_PREFIX

bp = Blueprint("api_v1", __name__, url_prefix=API_V1_PREFIX)

bp.register_blueprint(icebreaker_bp)
bp.register_blueprint(reply_bp)
bp.register_blueprint(jobs_bp)
