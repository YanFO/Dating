"""Initialize databases (PostgreSQL + MongoDB).

Usage:
    python -m scripts.init_db
"""

import asyncio
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config.settings import load_settings
from config.logging import setup_logging
from infra.database.engine import create_motor_client, get_database
from infra.database.models import Base
from infra.database.postgres import create_pg_engine


async def init():
    settings = load_settings()

    # PostgreSQL
    print(f"Initializing PostgreSQL: {settings.POSTGRES_DATABASE}")
    pg_engine = create_pg_engine(settings)
    async with pg_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    print(f"PostgreSQL tables created: {list(Base.metadata.tables.keys())}")
    await pg_engine.dispose()

    # MongoDB (conversation_logs only)
    print(f"Initializing MongoDB: {settings.MONGODB_DATABASE}")
    client = create_motor_client(settings)
    db = get_database(client, settings.MONGODB_DATABASE)

    existing = await db.list_collection_names()
    if "conversation_logs" not in existing:
        await db.create_collection("conversation_logs")
    await db.conversation_logs.create_index("session_id")
    await db.conversation_logs.create_index("user_id")
    await db.conversation_logs.create_index("created_at")

    print("MongoDB conversation_logs collection initialized.")
    client.close()
    print("All databases initialized successfully.")


if __name__ == "__main__":
    settings = load_settings()
    setup_logging(settings)
    asyncio.run(init())
