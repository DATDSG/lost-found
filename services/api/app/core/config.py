from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    APP_NAME: str = "lostfound-api"
    ENV: str = "dev"
    PORT: int = 8000
    CORS_ORIGINS: str = "*"

    # Auth
    JWT_SECRET: str = "change_me"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    # DB
    DATABASE_URL: str = "sqlite:///./local.db"

    # S3
    S3_ENDPOINT_URL: str | None = None
    S3_REGION: str | None = None
    S3_ACCESS_KEY_ID: str | None = None
    S3_SECRET_ACCESS_KEY: str | None = None
    S3_BUCKET: str | None = None
    S3_PRESIGN_EXPIRES: int = 3600

    # Redis / RQ
    REDIS_URL: str = "redis://localhost:6379/0"
    RQ_DEFAULT_QUEUE: str = "lostfound"

    class Config:
        env_file = ".env"

settings = Settings()