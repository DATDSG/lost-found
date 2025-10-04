@echo off
REM Start the Lost & Found API service locally

REM Set environment variables
set DATABASE_URL=postgresql://lostfound:lostfound@localhost:5432/lostfound
set REDIS_URL=redis://localhost:6379
set JWT_SECRET=local-dev-secret-key
set ADMIN_EMAIL=admin@localhost
set ADMIN_PASSWORD=admin123

REM Change to API directory
cd /d "%~dp0backend\api"

REM Start the API with uvicorn
echo Starting API service on http://localhost:8000
"%~dp0.venv\Scripts\python.exe" -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
