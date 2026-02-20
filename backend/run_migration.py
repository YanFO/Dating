"""Database migration runner.

Handles both PostgreSQL (primary) and MongoDB (conversation logs).

Usage:
    python run_migration.py
"""

import asyncio

import structlog

from config.settings import load_settings
from config.logging import setup_logging
from infra.database.engine import create_motor_client, get_database
from infra.database.models import Base
from infra.database.postgres import create_pg_engine

logger = structlog.get_logger()


async def run_migrations():
    settings = load_settings()

    # --- PostgreSQL migrations ---
    logger.info("pg_migration_start")
    pg_engine = create_pg_engine(settings)
    async with pg_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    logger.info("pg_migration_complete", tables=list(Base.metadata.tables.keys()))
    await pg_engine.dispose()

    # --- MongoDB migrations (conversation_logs only) ---
    logger.info("mongo_migration_start")
    client = create_motor_client(settings)
    db = get_database(client, settings.MONGODB_DATABASE)

    collections = await db.list_collection_names()

    if "conversation_logs" not in collections:
        await db.create_collection("conversation_logs")
        logger.info("collection_created", name="conversation_logs")

    # Indexes for conversation_logs
    await db.conversation_logs.create_index("session_id")
    await db.conversation_logs.create_index("user_id")
    await db.conversation_logs.create_index("created_at")

    logger.info("mongo_migration_complete")
    client.close()


def main():
    settings = load_settings()
    setup_logging(settings)
    asyncio.run(run_migrations())


if __name__ == "__main__":
    main()
