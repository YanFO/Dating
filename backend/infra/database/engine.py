"""MongoDB 客户端模块，使用 Motor 异步驱动创建连接与获取数据库实例。"""

import structlog
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase

logger = structlog.get_logger()


def create_motor_client(settings) -> AsyncIOMotorClient:
    """根据配置创建 Motor 异步 MongoDB 客户端。"""
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
    """根据数据库名称获取 MongoDB 数据库实例。"""
    return client[db_name]
