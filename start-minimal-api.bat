@echo off
REM Start the Lost & Found API service in minimal mode (health endpoints only)

REM Change to API directory
cd /d "%~dp0backend\api"

REM Start the minimal API with uvicorn
echo Starting Minimal API service on http://localhost:8000
echo Only health endpoints: /healthz, /readyz, /
"%~dp0.venv\Scripts\python.exe" -m uvicorn app.main_minimal:app --reload --host 0.0.0.0 --port 8000
