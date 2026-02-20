import structlog
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

logger = structlog.get_logger()


def create_pg_engine(settings) -> AsyncEngine:
    logger.info(
        "pg_engine_creating",
        host=settings.POSTGRES_HOST,
        port=settings.POSTGRES_PORT,
        database=settings.POSTGRES_DATABASE,
    )
    engine = create_async_engine(
        settings.postgres_dsn,
        pool_size=settings.POSTGRES_MAX_CONNECTIONS,
        max_overflow=5,
        pool_timeout=settings.POSTGRES_CONNECTION_TIMEOUT,
        pool_recycle=3600,
        echo=settings.ENV == "dev",
    )
    return engine


def create_pg_session_factory(engine: AsyncEngine) -> async_sessionmaker[AsyncSession]:
    return async_sessionmaker(engine, expire_on_commit=False)
