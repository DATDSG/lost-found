# API Service

FastAPI-based REST API for the Lost & Found system.

## Features

- **Authentication**: JWT-based authentication with role-based access control
- **Item Management**: CRUD operations for lost/found items
- **Matching Algorithm**: Configurable matching with geo-temporal filtering
- **Chat System**: Real-time messaging with privacy features
- **Media Handling**: S3/MinIO integration for image storage
- **Notifications**: Email, SMS, and push notification support
- **Admin Panel**: User moderation and system management

## Tech Stack

- FastAPI 0.104+
- SQLAlchemy 2.0 with PostgreSQL + PostGIS
- Alembic for database migrations
- Celery for background tasks
- Redis for caching and queuing
- JWT for authentication
- Boto3 for S3/MinIO

## Setup

1. **Install dependencies**:

   ```bash
   pip install -r requirements.txt
   ```

2. **Configure environment**:

   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

3. **Setup database**:

   ```bash
   # Create database with PostGIS
   createdb lostfound
   psql -d lostfound -c "CREATE EXTENSION postgis;"

   # Run migrations
   alembic upgrade head
   ```

4. **Run the server**:
   ```bash
   uvicorn app.main:app --reload --port 8000
   ```

## API Documentation

Once running, access interactive API docs:

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Project Structure

```
app/
├── api/              # API endpoints
│   ├── auth.py       # Authentication endpoints
│   ├── items.py      # Item CRUD
│   ├── matches.py    # Matching endpoints
│   ├── chat.py       # Chat messaging
│   └── admin.py      # Admin operations
├── core/             # Core configuration
│   ├── config.py     # Settings
│   ├── security.py   # JWT, hashing
│   └── deps.py       # Dependencies
├── db/               # Database
│   ├── models.py     # SQLAlchemy models
│   └── session.py    # DB session
├── schemas/          # Pydantic schemas
├── services/         # Business logic
│   ├── matching.py   # Matching algorithm
│   ├── notifications.py
│   └── media.py
└── main.py           # FastAPI app
```

## Environment Variables

Key variables (see `.env.example` for complete list):

- `DATABASE_URL`: PostgreSQL connection string
- `JWT_SECRET`: Secret key for JWT (CHANGE IN PRODUCTION!)
- `REDIS_URL`: Redis connection string
- `S3_*`: S3/MinIO configuration
- `NLP_ON`, `CV_ON`: Feature flags for optional services

## Running Tests

```bash
pytest
pytest --cov=app tests/
```

## Database Migrations

```bash
# Create a new migration
alembic revision --autogenerate -m "description"

# Apply migrations
alembic upgrade head

# Rollback
alembic downgrade -1
```

## Deployment

### Docker

```bash
docker build -t lostfound-api .
docker run -p 8000:8000 --env-file .env lostfound-api
```

### Production Checklist

- [ ] Change JWT_SECRET to secure random string
- [ ] Change ADMIN_PASSWORD
- [ ] Configure proper CORS_ORIGINS
- [ ] Setup SSL/TLS
- [ ] Configure production database
- [ ] Setup Redis with persistence
- [ ] Configure S3 or cloud storage
- [ ] Enable Sentry for error tracking
- [ ] Setup log aggregation
- [ ] Configure backup strategy
