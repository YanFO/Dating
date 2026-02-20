"""Seed development test data.

Usage:
    python -m scripts.seed
"""

import asyncio
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config.settings import load_settings
from config.logging import setup_logging
from infra.database.models import User, Session as SessionModel
from infra.database.postgres import create_pg_engine, create_pg_session_factory
from infra.database.engine import create_motor_client, get_database


async def seed():
    settings = load_settings()

    # PostgreSQL seed
    print("Seeding PostgreSQL...")
    engine = create_pg_engine(settings)
    session_factory = create_pg_session_factory(engine)

    async with session_factory() as session:
        session.add(User(user_id="seed_user_001", display_name="Test User", role="user"))
        session.add(SessionModel(
            session_id="seed_session_001",
            user_id="seed_user_001",
            feature="icebreaker",
            status="completed",
        ))
        await session.commit()
    print("PostgreSQL seed data inserted.")
    await engine.dispose()

    # MongoDB seed (conversation log)
    print("Seeding MongoDB...")
    client = create_motor_client(settings)
    db = get_database(client, settings.MONGODB_DATABASE)

    await db.conversation_logs.insert_one({
        "session_id": "seed_session_001",
        "user_id": "seed_user_001",
        "feature": "icebreaker",
        "messages": [
            {"role": "user", "content": "在星巴克看到一個女生"},
            {"role": "coach", "content": "你可以試試觀察她正在做什麼..."},
        ],
        "created_at": "2026-02-20T00:00:00Z",
    })

    print("MongoDB seed data inserted.")
    client.close()
    print("All seed data inserted successfully.")


if __name__ == "__main__":
    settings = load_settings()
    setup_logging(settings)
    asyncio.run(seed())
