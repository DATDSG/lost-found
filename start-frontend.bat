@echo off
REM Start the Lost & Found Web Admin Frontend

REM Change to web-admin directory
cd /d "%~dp0frontend\web-admin"

REM Start the Next.js development server
echo Starting Web Admin Frontend on http://localhost:3000
echo API URL: http://localhost:8000
npm run dev
