"""应用配置模块，使用 pydantic-settings 从环境变量加载配置项。"""

from pydantic_settings import BaseSettings
from pydantic import Field
from typing import Optional


class Settings(BaseSettings):
    """应用全局配置类，包含 OpenAI、数据库、服务器等所有环境变量配置。"""
    # OpenAI
    OPENAI_API_KEY: str = Field(..., description="OpenAI API key")
    OPENAI_MODEL: str = Field(default="gpt-4o", description="OpenAI model name")

    # MongoDB (conversation logs only)
    MONGODB_URI: str = Field(..., description="MongoDB Atlas connection string")
    MONGODB_DATABASE: str = Field(default="Lens")

    # PostgreSQL (primary relational data)
    POSTGRES_USER: str = Field(default="lensadmin")
    POSTGRES_PASSWORD: str = Field(default="")
    POSTGRES_PORT: int = Field(default=5433)
    POSTGRES_DATABASE: str = Field(default="lens_dating")
    POSTGRES_HOST: str = Field(default="localhost")
    POSTGRES_MAX_CONNECTIONS: int = Field(default=10)
    POSTGRES_CONNECTION_TIMEOUT: int = Field(default=30)

    @property
    def postgres_dsn(self) -> str:
        """拼接 PostgreSQL 异步连接字符串。"""
        return (
            f"postgresql+asyncpg://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}"
            f"@{self.POSTGRES_HOST}:{self.POSTGRES_PORT}/{self.POSTGRES_DATABASE}"
        )

    # Brave Search
    BRAVE_API_KEY: Optional[str] = None

    # Google
    GOOGLE_API_KEY: Optional[str] = None
    GOOGLE_SEARCH_CX: Optional[str] = None
    GOOGLE_GEMINI_MODEL: Optional[str] = None

    # OpenAI Realtime（語音教練）
    OPENAI_REALTIME_URL: str = Field(
        default="wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview",
        description="OpenAI Realtime API WebSocket URL",
    )

    # Server
    ENV: str = Field(default="dev")
    HOST: str = Field(default="0.0.0.0")
    PORT: int = Field(default=8000)
    LOG_LEVEL: str = Field(default="INFO")
    CORS_ORIGINS: str = Field(default="*")

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
    }


def load_settings() -> Settings:
    """加载并返回应用配置实例。"""
    return Settings()
