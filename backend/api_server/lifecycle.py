import structlog

from clients.llm.gemini_client import GeminiClient
from clients.llm.openai_client import OpenAIClient
from config.feature_flags import FeatureFlags
from infra.database.engine import create_motor_client, get_database
from infra.database.postgres import create_pg_engine, create_pg_session_factory
from modules.icebreaker.service import IcebreakerService
from modules.jobs.service import JobService
from modules.reply.service import ReplyService
from modules.voice_coach.service import VoiceCoachService
from services.stream_service import StreamService

logger = structlog.get_logger()


def register_lifecycle(app):
    @app.before_serving
    async def startup():
        settings = app.config["SETTINGS"]
        flags = app.config.get("FEATURE_FLAGS", FeatureFlags())
        logger.info("startup_begin", env=settings.ENV)

        # --- PostgreSQL (primary relational data) ---
        pg_engine = create_pg_engine(settings)
        pg_session_factory = create_pg_session_factory(pg_engine)
        app.config["pg_engine"] = pg_engine
        app.config["pg_session_factory"] = pg_session_factory

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

        # OpenAI for Feature 3 (voice coach realtime API only)
        openai_client = OpenAIClient(api_key=settings.OPENAI_API_KEY)
        app.config["openai_client"] = openai_client

        # --- Services ---
        stream_service = StreamService()
        app.config["stream_service"] = stream_service

        # --- Modules ---
        app.config["icebreaker_service"] = IcebreakerService(gemini_client, flags)
        app.config["reply_service"] = ReplyService(gemini_client, flags)
        app.config["job_service"] = JobService()

        if flags.ENABLE_VOICE_COACH:
            app.config["voice_coach_service"] = VoiceCoachService(
                api_key=settings.OPENAI_API_KEY,
                stream_service=stream_service,
            )
            logger.info("voice_coach_enabled")

        logger.info("startup_complete")

    @app.after_serving
    async def shutdown():
        logger.info("shutdown_begin")

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
