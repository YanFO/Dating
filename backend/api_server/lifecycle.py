"""應用程式生命週期管理

註冊 Quart app 的 startup / shutdown hooks。
startup 負責初始化所有外部連線（DB、LLM）與業務服務。
shutdown 負責優雅釋放資源。
"""

import structlog

from clients.auth_db_client import init_auth_pool, close_auth_pool
from clients.llm.gemini_client import GeminiClient
from clients.llm.openai_client import OpenAIClient
from config.feature_flags import FeatureFlags
from infra.database.engine import create_motor_client, get_database
from infra.database.models import Base
from infra.database.postgres import create_pg_engine, create_pg_session_factory
from modules.icebreaker.service import IcebreakerService
from modules.insights.service import InsightsService
from modules.jobs.service import JobService
from modules.match.service import MatchService
from modules.persona.service import PersonaService
from modules.reply.service import ReplyService
from modules.love_coach.service import LoveCoachService
from modules.voice_coach.service import VoiceCoachService
from services.stream_service import StreamService

logger = structlog.get_logger()

# Seed 數據用的預設用戶 ID（僅用於 startup seed，不在業務邏輯中使用）
SEED_USER_ID = "anonymous"


def register_lifecycle(app):
    @app.before_serving
    async def startup():
        settings = app.config["SETTINGS"]
        flags = app.config.get("FEATURE_FLAGS", FeatureFlags())
        logger.info("startup_begin", env=settings.ENV)

        # --- Auth Database (shared lens_account) ---
        if settings.AUTH_DATABASE_URL:
            await init_auth_pool(settings.AUTH_DATABASE_URL)
            logger.info("auth_db_pool_initialized")

        # --- PostgreSQL (primary relational data) ---
        pg_engine = create_pg_engine(settings)
        pg_session_factory = create_pg_session_factory(pg_engine)
        app.config["pg_engine"] = pg_engine
        app.config["pg_session_factory"] = pg_session_factory

        # 自動建立所有資料表（若尚未存在）
        async with pg_engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        logger.info("pg_tables_created")

        # --- MongoDB (conversation logs only) ---
        motor_client = create_motor_client(settings)
        mongo_db = get_database(motor_client, settings.MONGODB_DATABASE)
        app.config["motor_client"] = motor_client
        app.config["mongo_db"] = mongo_db

        # --- LLM Clients ---
        # Gemini for Feature 1 (icebreaker) & Feature 2 (reply)
        gemini_client = GeminiClient(
            api_key=settings.GOOGLE_API_KEY,
            model=settings.GOOGLE_GEMINI_MODEL or "gemini-3-pro-preview",
        )
        app.config["gemini_client"] = gemini_client
        logger.info("gemini_client_initialized", model=settings.GOOGLE_GEMINI_MODEL)

        # OpenAI for Feature 1 & 2 (icebreaker / reply) + voice coach
        openai_model = settings.OPENAI_MODEL or "gpt-4o"
        openai_client = OpenAIClient(api_key=settings.OPENAI_API_KEY, model=openai_model)
        app.config["openai_client"] = openai_client
        logger.info("openai_client_initialized", model=openai_model)

        # --- Services ---
        stream_service = StreamService()
        app.config["stream_service"] = stream_service

        # --- Modules（全部注入 pg_session_factory）---
        app.config["icebreaker_service"] = IcebreakerService(
            gemini_client, flags, pg_session_factory, fallback_client=openai_client,
        )
        match_service = MatchService(
            pg_session_factory,
            llm_client=gemini_client,
            fallback_client=openai_client,
        )
        app.config["match_service"] = match_service
        app.config["reply_service"] = ReplyService(
            gemini_client, flags, pg_session_factory, fallback_client=openai_client,
            match_service=match_service,
        )
        app.config["job_service"] = JobService(pg_session_factory)
        app.config["persona_service"] = PersonaService(
            gemini_client, flags, pg_session_factory, fallback_client=openai_client,
        )
        app.config["insights_service"] = InsightsService(pg_session_factory)

        # Love Coach（使用 Gemini 串流聊天，受功能開關控制）
        if flags.ENABLE_LOVE_COACH:
            app.config["love_coach_service"] = LoveCoachService(
                gemini_client, flags, pg_session_factory,
            )
            logger.info("love_coach_service_initialized")
        else:
            logger.info("love_coach_disabled")

        # 確保預設用戶有 Insights seed 數據
        insights_svc: InsightsService = app.config["insights_service"]
        await insights_svc.ensure_seed_data(SEED_USER_ID)

        if flags.ENABLE_VOICE_COACH:
            app.config["voice_coach_service"] = VoiceCoachService(
                api_key=settings.OPENAI_API_KEY,
                stream_service=stream_service,
                realtime_url=settings.OPENAI_REALTIME_URL,
                session_factory=pg_session_factory,
                gemini_client=gemini_client,
            )
            logger.info("voice_coach_enabled")

        logger.info("startup_complete")

    @app.after_serving
    async def shutdown():
        logger.info("shutdown_begin")

        # Auth Database
        await close_auth_pool()

        # 語音教練：關閉所有活躍會話
        voice_coach_svc = app.config.get("voice_coach_service")
        if voice_coach_svc:
            await voice_coach_svc.close_all_sessions()

        # PostgreSQL
        pg_engine = app.config.get("pg_engine")
        if pg_engine:
            await pg_engine.dispose()

        # MongoDB
        motor_client = app.config.get("motor_client")
        if motor_client:
            motor_client.close()

        # LLM clients
        gemini_client = app.config.get("gemini_client")
        if gemini_client:
            await gemini_client.close()

        openai_client = app.config.get("openai_client")
        if openai_client:
            await openai_client.close()

        logger.info("shutdown_complete")
