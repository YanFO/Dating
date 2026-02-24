"""Auth Database Client for shared lens_account database.

Uses asyncpg for async operations against the authentication database
(User, Account, Session tables in PascalCase / Prisma format).
"""

from contextlib import asynccontextmanager
from typing import AsyncGenerator
from urllib.parse import urlparse

import asyncpg
from asyncpg import Pool, Connection

import structlog

logger = structlog.get_logger()

_pool: Pool | None = None


class AuthDbSession:
    """Wrapper providing named-parameter support over asyncpg Connection."""

    def __init__(self, conn: Connection):
        self._conn = conn

    async def execute(self, query: str, params: dict | None = None):
        """Execute a query with :named parameters, converted to $1, $2, etc."""
        query_str = str(query)

        if params:
            param_values = []
            param_index = 1
            for key in sorted(params.keys(), key=len, reverse=True):
                placeholder = f":{key}"
                if placeholder in query_str:
                    query_str = query_str.replace(placeholder, f"${param_index}")
                    param_values.append(params[key])
                    param_index += 1
            result = await self._conn.fetch(query_str, *param_values)
        else:
            result = await self._conn.fetch(query_str)

        return _ResultProxy(result)


class _ResultProxy:
    """Proxy providing fetchone/fetchall interface for asyncpg results."""

    def __init__(self, rows):
        self._rows = rows
        self._index = 0

    def fetchone(self):
        if self._index < len(self._rows):
            row = self._rows[self._index]
            self._index += 1
            return tuple(row.values())
        return None

    def fetchall(self):
        return [tuple(row.values()) for row in self._rows]


async def init_auth_pool(auth_database_url: str) -> None:
    """Initialize the auth DB connection pool from a DATABASE_URL string."""
    global _pool
    if _pool is not None:
        return

    if not auth_database_url:
        logger.warning("auth_db_skip", reason="AUTH_DATABASE_URL is empty")
        return

    parsed = urlparse(auth_database_url)
    _pool = await asyncpg.create_pool(
        host=parsed.hostname or "localhost",
        port=parsed.port or 5432,
        user=parsed.username or "lensadmin",
        password=parsed.password or "",
        database=(parsed.path or "/lens_account").lstrip("/"),
        min_size=2,
        max_size=10,
        command_timeout=30,
    )
    logger.info("auth_db_pool_created", host=parsed.hostname, database=(parsed.path or "").lstrip("/"))


@asynccontextmanager
async def get_auth_db_session() -> AsyncGenerator[AuthDbSession, None]:
    """Yield an AuthDbSession backed by a pooled connection."""
    if _pool is None:
        raise RuntimeError("Auth DB pool not initialized. Call init_auth_pool() first.")
    async with _pool.acquire() as conn:
        yield AuthDbSession(conn)


async def close_auth_pool() -> None:
    """Close the auth DB connection pool."""
    global _pool
    if _pool is not None:
        await _pool.close()
        _pool = None
        logger.info("auth_db_pool_closed")
