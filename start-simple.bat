@echo off
echo ==========================================
echo "Starting Lost and Found System Locally"
echo "(Minimal setup without expensive APIs)"
echo ==========================================

echo.
echo Step 1: Setting up environment...
if not exist .env (
    echo Copying local environment configuration...
    copy .env.local .env
) else (
    echo .env file already exists, skipping copy
)

echo.
echo Step 2: Starting Docker services...
echo This will start PostgreSQL, Redis, API, NLP, and Vision services
echo (Worker service excluded for now to avoid complexity)

cd deployment
docker-compose -f docker-compose-simple.yml up --build

echo.
echo ==========================================
echo Services should be running on:
echo - API: http://localhost:8000
echo - Database: localhost:5432
echo - Redis: localhost:6379
echo - NLP Service: http://localhost:8090
echo - Vision Service: http://localhost:8091
echo ==========================================
echo.
echo Admin login: admin@localhost / admin123
echo API Documentation: http://localhost:8000/docs
echo.
echo Press Ctrl+C to stop all services
pause