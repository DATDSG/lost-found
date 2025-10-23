@echo off
REM Lost & Found Admin Panel Setup Script for Windows

echo 🚀 Setting up Lost & Found Admin Panel...

REM Check if Node.js is installed
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js is not installed. Please install Node.js first.
    pause
    exit /b 1
)

REM Check if npm is installed
npm --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ npm is not installed. Please install npm first.
    pause
    exit /b 1
)

echo ✅ Node.js and npm are installed

REM Install dependencies
echo 📦 Installing dependencies...
npm install

if %errorlevel% neq 0 (
    echo ❌ Failed to install dependencies
    pause
    exit /b 1
)

echo ✅ Dependencies installed successfully

REM Create .env.local if it doesn't exist
if not exist .env.local (
    echo 📝 Creating .env.local file...
    (
        echo # API Configuration
        echo NEXT_PUBLIC_API_URL=http://localhost:8000
        echo.
        echo # Authentication ^(if needed^)
        echo NEXT_PUBLIC_AUTH_ENABLED=true
        echo.
        echo # Feature Flags
        echo NEXT_PUBLIC_FRAUD_DETECTION_ENABLED=true
        echo NEXT_PUBLIC_AUDIT_LOGS_ENABLED=true
        echo.
        echo # Development
        echo NODE_ENV=development
    ) > .env.local
    echo ✅ .env.local file created
) else (
    echo ℹ️  .env.local file already exists
)

echo.
echo 🎉 Setup complete!
echo.
echo Next steps:
echo 1. Update the API URL in .env.local to point to your backend
echo 2. Run 'npm run dev' to start the development server
echo 3. Open http://localhost:3000 in your browser
echo.
echo Happy coding! 🚀
pause
