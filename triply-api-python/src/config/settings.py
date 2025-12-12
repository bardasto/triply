"""
Environment Configuration

Centralized settings management using Pydantic Settings
"""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # Server
    port: int = 3001
    env: str = "development"

    # Google AI (Gemini)
    google_api_key: str

    # Google Places API
    google_places_api_key: str | None = None

    # Tavily Web Search
    tavily_api_key: str | None = None

    # LangSmith Tracing
    langchain_tracing_v2: bool = False
    langchain_api_key: str | None = None
    langchain_project: str = "triply-api"

    # Sentry
    sentry_dsn: str | None = None

    @property
    def is_dev(self) -> bool:
        return self.env == "development"

    @property
    def is_prod(self) -> bool:
        return self.env == "production"

    @property
    def places_api_key(self) -> str:
        """Get Places API key, fallback to general Google API key"""
        return self.google_places_api_key or self.google_api_key


settings = Settings()  # type: ignore[call-arg]
