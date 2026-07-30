"""
Centralized application settings, loaded from environment variables (see
.env.example). Every other module imports `settings` from here instead of
calling `os.getenv` directly, so config is validated once at startup and
fully typed everywhere else.
"""
from functools import lru_cache
from typing import List

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # App
    APP_NAME: str = "LycanOS AI"
    APP_ENV: str = "development"
    DEBUG: bool = True
    API_V1_PREFIX: str = "/api/v1"

    # Security
    SECRET_KEY: str = "change-me-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://lycanos:lycanos@localhost:5432/lycanos_db"

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # CORS — Flutter web/desktop dev origins by default. Stored as a plain
    # comma-separated string (not List[str]) because pydantic-settings
    # attempts JSON parsing on complex-typed env vars before validators
    # run, which makes a plain ".env" comma list awkward. Use
    # `cors_origins_list` below to get the parsed list.
    CORS_ORIGINS: str = "http://localhost:3000,http://localhost:8080,http://localhost:5000"

    # AI
    OLLAMA_BASE_URL: str = "http://localhost:11434"
    OLLAMA_MODEL: str = "llama3.1"
    CHROMA_PERSIST_DIR: str = "./chroma_data"

    @property
    def cors_origins_list(self) -> List[str]:
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",") if origin.strip()]

    @property
    def is_production(self) -> bool:
        return self.APP_ENV == "production"


@lru_cache
def get_settings() -> Settings:
    """Cached settings accessor — FastAPI dependencies should use
    `Depends(get_settings)` rather than importing the module-level
    `settings` directly, to keep tests able to override config cleanly."""
    return Settings()


settings = get_settings()
