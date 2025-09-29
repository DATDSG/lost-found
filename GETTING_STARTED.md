# Getting Started Guide

Welcome to the Lost & Found System! This guide will help you set up and run the complete trilingual lost and found platform.

## Quick Start

### Prerequisites

Make sure you have the following installed:

- **Python 3.11+** (for backend services)
- **Node.js 18+** and **npm 9+** (for web admin)
- **Flutter 3.19+** (for mobile app)
- **PostgreSQL 15+** with PostGIS extension
- **Redis 7+** (optional, for caching)
- **Git** (for version control)

### 1. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/DATDSG/lost-found.git
cd lost-found

# Copy environment configuration
cp .env.example .env
# Edit .env with your actual configuration values

# Install all dependencies
make install
# or manually:
# npm install (root level)
# cd frontend/web-admin && npm install
# cd backend/api && pip install -r requirements.txt
# cd frontend/mobile && flutter pub get
```

### 2. Database Setup

```bash
# Create PostgreSQL database
createdb lostfound

# Enable PostGIS extension
psql lostfound -c "CREATE EXTENSION postgis;"

# Run database migrations
cd backend/api
alembic upgrade head

# (Optional) Seed with sample data
python -c "from app.db.init_db import init_db; init_db()"
```

### 3. Start Development Services

#### Option A: Using Make (Recommended)

```bash
# Start all services
make dev
```

#### Option B: Manual Startup

```bash
# Terminal 1: API Service
cd backend/api
uvicorn app.main:app --reload --port 8000

# Terminal 2: NLP Service
cd backend/nlp
python server/main.py

# Terminal 3: Vision Service
cd backend/vision
python server/main.py

# Terminal 4: Web Admin
cd frontend/web-admin
npm run dev

# Terminal 5: (Optional) Background Worker
cd backend/worker
celery -A worker.worker worker --loglevel=info
```

### 4. Access Applications

- **API Documentation**: http://localhost:8000/docs
- **Web Admin Dashboard**: http://localhost:3000
- **API Health Check**: http://localhost:8000/health

### 5. Mobile App Development

```bash
# Navigate to mobile directory
cd frontend/mobile

# Run on connected device/emulator
flutter run

# Or specify platform
flutter run -d ios      # iOS
flutter run -d android  # Android
```

## Docker Development (Alternative)

If you prefer using Docker:

```bash
# Start all services with Docker
make docker-up

# Or manually
cd deployment
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
make docker-down
```

## Testing

```bash
# Run all tests
make test

# Or individual test suites
make test-web     # Web admin tests
make test-api     # API tests
make test-mobile  # Mobile tests
```

## Project Structure Overview

```
lost-found/
├── frontend/          # Frontend applications
│   ├── web-admin/    # Admin dashboard (Next.js)
│   └── mobile/       # Mobile app (Flutter)
├── backend/          # Backend services
│   ├── api/         # Main API (FastAPI)
│   ├── nlp/         # NLP service
│   ├── vision/      # Computer vision service
│   └── worker/      # Background jobs
├── shared/          # Shared configurations
├── deployment/      # Docker configurations
├── docs/           # Documentation
└── tools/          # Development tools
```

## Development Workflow

1. **Feature Development**:

   - Create feature branch from `main`
   - Develop and test locally
   - Run tests: `make test`
   - Submit pull request

2. **Code Quality**:

   - Lint code: `make lint`
   - Format code: `make format`
   - Follow project conventions

3. **Database Changes**:
   - Create migration: `alembic revision -m "description"`
   - Apply migration: `make db-migrate`

## Common Tasks

### Adding New API Endpoints

1. Create endpoint in `backend/api/app/api/`
2. Add schemas in `backend/api/app/schemas/`
3. Update database models if needed
4. Write tests
5. Update API documentation

### Adding Mobile Features

1. Create feature in `frontend/mobile/lib/features/`
2. Add UI components in respective `ui/` folders
3. Update routing and navigation
4. Add translations if needed
5. Test on both platforms

### Environment Configuration

Key environment variables in `.env`:

```bash
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/lostfound

# Services
NLP_SERVICE_URL=http://localhost:8090
VISION_SERVICE_URL=http://localhost:8091

# Authentication
JWT_SECRET_KEY=your-secret-key

# Features
ENABLE_NLP=true
ENABLE_VISION=true
```

## Troubleshooting

### Common Issues

1. **Database Connection Error**:

   - Check PostgreSQL is running
   - Verify DATABASE_URL in .env
   - Ensure PostGIS extension is installed

2. **Service Connection Issues**:

   - Check all services are running on correct ports
   - Verify firewall settings
   - Check service URLs in configuration

3. **Mobile App Issues**:

   - Run `flutter doctor` to check setup
   - Clean build: `flutter clean && flutter pub get`
   - Verify API endpoints are accessible

4. **Docker Issues**:
   - Check Docker is running
   - Verify port conflicts
   - Check container logs: `docker-compose logs service-name`

### Getting Help

- Check the `docs/` directory for detailed documentation
- Review API documentation at http://localhost:8000/docs
- Check existing issues in the repository
- Contact the development team

## Next Steps

- Explore the [Architecture Documentation](docs/architecture.md)
- Review [API Documentation](docs/api.md)
- Check out [Deployment Guide](docs/deployment.md)
- Read [Mobile App Guide](docs/mobile.md)

Happy coding! 🚀
