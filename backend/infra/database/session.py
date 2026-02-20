from motor.motor_asyncio import AsyncIOMotorCollection, AsyncIOMotorDatabase


class DatabaseSession:
    def __init__(self, db: AsyncIOMotorDatabase):
        self._db = db

    def get_collection(self, name: str) -> AsyncIOMotorCollection:
        return self._db[name]
