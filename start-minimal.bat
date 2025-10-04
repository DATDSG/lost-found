@echo off
echo ==========================================
echo "Starting Lost and Found - MINIMAL SETUP"
echo "(Database + API only for initial testing)"
echo ==========================================

echo.
echo This minimal setup includes:
echo - PostgreSQL database with PostGIS
echo - Redis for caching
echo - Basic API service (no ML features)
echo.

echo Step 1: Setting up environment...
if not exist .env (
    echo Copying local environment configuration...
    copy .env.local .env
) else (
    echo .env file already exists, skipping copy
)

echo.
echo Step 2: Starting minimal Docker services...
cd deployment
docker-compose -f docker-compose-minimal.yml up --build

echo.
echo ==========================================
echo Minimal services running on:
echo - API: http://localhost:8000
echo - Database: localhost:5432
echo - Redis: localhost:6379
echo ==========================================
echo.
echo Admin login: admin@localhost / admin123
echo API Documentation: http://localhost:8000/docs
echo.
echo To test: curl http://localhost:8000/health
echo.
echo Press Ctrl+C to stop all services
pause