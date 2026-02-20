import structlog
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase

logger = structlog.get_logger()


def create_motor_client(settings) -> AsyncIOMotorClient:
    logger.info("motor_client_creating", database=settings.MONGODB_DATABASE)
    client = AsyncIOMotorClient(
        settings.MONGODB_URI,
        maxPoolSize=50,
        minPoolSize=5,
        serverSelectionTimeoutMS=5000,
        connectTimeoutMS=5000,
    )
    return client


def get_database(client: AsyncIOMotorClient, db_name: str) -> AsyncIOMotorDatabase:
    return client[db_name]
