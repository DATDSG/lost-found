@echo off
REM ================================================================
REM Lost & Found Deployment Script - Windows Version
REM ================================================================
REM Comprehensive deployment script for the Lost & Found application
REM Supports both local and server deployment configurations
REM ================================================================

setlocal enabledelayedexpansion

REM Configuration
set PROJECT_NAME=lost-found
set COMPOSE_FILE=infra\compose\docker-compose.yml
set ENV_FILE=infra\compose\env.development
set SERVER_IP=172.104.40.189

REM Functions
:log_info
echo [INFO] %~1
goto :eof

:log_success
echo [SUCCESS] %~1
goto :eof

:log_warning
echo [WARNING] %~1
goto :eof

:log_error
echo [ERROR] %~1
goto :eof

REM Check prerequisites
:check_prerequisites
call :log_info "Checking prerequisites..."

REM Check Docker
docker --version >nul 2>&1
if errorlevel 1 (
    call :log_error "Docker is not installed. Please install Docker first."
    exit /b 1
)

REM Check Docker Compose
docker compose version >nul 2>&1
if errorlevel 1 (
    call :log_error "Docker Compose is not installed. Please install Docker Compose first."
    exit /b 1
)

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    call :log_error "Docker is not running. Please start Docker first."
    exit /b 1
)

call :log_success "Prerequisites check passed"
goto :eof

REM Create necessary directories
:create_directories
call :log_info "Creating necessary directories..."

if not exist "infra\compose\nginx\conf.d" mkdir "infra\compose\nginx\conf.d"
if not exist "infra\compose\pgadmin" mkdir "infra\compose\pgadmin"
if not exist "infra\compose\init" mkdir "infra\compose\init"
if not exist "logs" mkdir "logs"
if not exist "data" mkdir "data"

call :log_success "Directories created"
goto :eof

REM Generate environment files
:generate_env_files
call :log_info "Generating environment files..."

REM Development environment
(
echo # ================================================================
echo # Lost ^& Found - Development Environment Configuration
echo # ================================================================
echo.
echo # Environment
echo ENVIRONMENT=development
echo NODE_ENV=development
echo DEBUG=true
echo.
echo # Database Configuration
echo POSTGRES_USER=postgres
echo POSTGRES_PASSWORD=postgres
echo POSTGRES_DB=lostfound
echo DB_PORT=5433
echo DB_POOL_SIZE=10
echo DB_MAX_OVERFLOW=20
echo DB_POOL_TIMEOUT=30
echo DB_ECHO=false
echo.
echo # Redis Configuration
echo REDIS_PASSWORD=LF_Redis_2025_Pass!
echo REDIS_PORT=6379
echo REDIS_MAX_CONNECTIONS=20
echo.
echo # MinIO Configuration
echo MINIO_ACCESS_KEY=minioadmin
echo MINIO_SECRET_KEY=minioadmin123
echo MINIO_PORT=9000
echo MINIO_CONSOLE_PORT=9001
echo.
echo # JWT Configuration
echo JWT_SECRET_KEY=super-secret-jwt-key-change-me-in-production
echo JWT_ALGORITHM=HS256
echo JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30
echo.
echo # Service Ports
echo API_PORT=8000
echo NLP_PORT=8001
echo VISION_PORT=8002
echo ADMIN_PORT=3000
echo NGINX_PORT=8080
echo PGADMIN_PORT=5050
echo.
echo # pgAdmin Configuration
echo PGADMIN_EMAIL=postgres
echo PGADMIN_PASSWORD=postgres
echo.
echo # CORS Configuration
echo CORS_ORIGINS=http://localhost:3000,http://localhost:8080,http://admin:3000,http://172.104.40.189:3000,http://172.104.40.189:8080,http://172.104.40.189:8000,http://172.104.40.189:8001,http://172.104.40.189:8002
echo.
echo # Application Settings
echo LOG_LEVEL=INFO
echo RATE_LIMIT_ENABLED=true
echo RATE_LIMIT_REQUESTS_PER_MINUTE=60
echo METRICS_ENABLED=true
echo.
echo # Domain-specific Settings
echo REPORTS_PER_PAGE=20
echo MATCHES_PER_PAGE=20
echo MAX_FILE_SIZE=10485760
echo ALLOWED_FILE_TYPES=image/jpeg,image/png,image/webp
echo.
echo # NLP Settings
echo SIMILARITY_THRESHOLD=0.7
echo FUZZY_MATCH_THRESHOLD=80
echo MAX_MATCHES=10
echo CACHE_TTL=3600
echo WORKER_CONCURRENCY=4
echo MAX_TEXT_LENGTH=10000
echo.
echo # Vision Settings
echo HASH_THRESHOLD_SIMILAR=10
echo HASH_THRESHOLD_MATCH=5
echo MAX_IMAGE_SIZE=10485760
echo MAX_IMAGE_DIMENSION=4096
) > "infra\compose\env.development"

call :log_success "Environment files generated"
goto :eof

REM Build services
:build_services
call :log_info "Building services..."

docker compose -f %COMPOSE_FILE% --env-file %ENV_FILE% build --parallel
if errorlevel 1 (
    call :log_error "Failed to build services"
    exit /b 1
)

call :log_success "Services built successfully"
goto :eof

REM Start services
:start_services
call :log_info "Starting services..."

REM Start infrastructure services first
docker compose -f %COMPOSE_FILE% --env-file %ENV_FILE% up -d db redis minio
if errorlevel 1 (
    call :log_error "Failed to start infrastructure services"
    exit /b 1
)

call :log_info "Waiting for infrastructure services to be ready..."
timeout /t 30 /nobreak >nul

REM Start ML services
docker compose -f %COMPOSE_FILE% --env-file %ENV_FILE% up -d nlp vision
if errorlevel 1 (
    call :log_error "Failed to start ML services"
    exit /b 1
)

call :log_info "Waiting for ML services to be ready..."
timeout /t 30 /nobreak >nul

REM Start API and worker
docker compose -f %COMPOSE_FILE% --env-file %ENV_FILE% up -d api worker
if errorlevel 1 (
    call :log_error "Failed to start API services"
    exit /b 1
)

call :log_info "Waiting for API service to be ready..."
timeout /t 30 /nobreak >nul

REM Start frontend and proxy
docker compose -f %COMPOSE_FILE% --env-file %ENV_FILE% up -d admin nginx pgadmin
if errorlevel 1 (
    call :log_error "Failed to start frontend services"
    exit /b 1
)

call :log_success "All services started successfully"
goto :eof

REM Check service health
:check_health
call :log_info "Checking service health..."

REM Check API service
curl -f http://localhost:8000/v1/health >nul 2>&1
if errorlevel 1 (
    call :log_warning "API service health check failed"
) else (
    call :log_success "API service is healthy"
)

REM Check NLP service
curl -f http://localhost:8001/health >nul 2>&1
if errorlevel 1 (
    call :log_warning "NLP service health check failed"
) else (
    call :log_success "NLP service is healthy"
)

REM Check Vision service
curl -f http://localhost:8002/health >nul 2>&1
if errorlevel 1 (
    call :log_warning "Vision service health check failed"
) else (
    call :log_success "Vision service is healthy"
)

REM Check Admin panel
curl -f http://localhost:3000/api/health >nul 2>&1
if errorlevel 1 (
    call :log_warning "Admin panel health check failed"
) else (
    call :log_success "Admin panel is healthy"
)

REM Check Nginx
curl -f http://localhost:8080/health >nul 2>&1
if errorlevel 1 (
    call :log_warning "Nginx health check failed"
) else (
    call :log_success "Nginx is healthy"
)
goto :eof

REM Show service URLs
:show_urls
call :log_info "Service URLs:"
echo.
echo 🌐 Web Services:
echo   Admin Panel:     http://localhost:3000
echo   Nginx Proxy:     http://localhost:8080
echo   pgAdmin:         http://localhost:5050
echo.
echo 🔧 API Services:
echo   API Service:     http://localhost:8000
echo   NLP Service:     http://localhost:8001
echo   Vision Service:  http://localhost:8002
echo.
echo 🗄️  Infrastructure:
echo   PostgreSQL:      localhost:5433
echo   Redis:           localhost:6379
echo   MinIO:           http://localhost:9000
echo   MinIO Console:   http://localhost:9001
echo.
echo 🌍 Server Access (172.104.40.189):
echo   Admin Panel:     http://172.104.40.189:3000
echo   API Service:     http://172.104.40.189:8000
echo   Nginx Proxy:     http://172.104.40.189:8080
echo.
echo 🔑 Default Credentials:
echo   Database:        postgres / postgres
echo   pgAdmin:         postgres / postgres
echo   MinIO:           minioadmin / minioadmin123
echo   Redis:           LF_Redis_2025_Pass!
goto :eof

REM Stop services
:stop_services
call :log_info "Stopping services..."

docker compose -f %COMPOSE_FILE% --env-file %ENV_FILE% down
if errorlevel 1 (
    call :log_error "Failed to stop services"
    exit /b 1
)

call :log_success "Services stopped"
goto :eof

REM Clean up
:cleanup
call :log_info "Cleaning up..."

docker compose -f %COMPOSE_FILE% --env-file %ENV_FILE% down -v --remove-orphans
docker system prune -f

call :log_success "Cleanup completed"
goto :eof

REM Show logs
:show_logs
call :log_info "Showing service logs..."

docker compose -f %COMPOSE_FILE% --env-file %ENV_FILE% logs -f
goto :eof

REM Main menu
:show_menu
echo.
echo ================================================================
echo Lost ^& Found Deployment Script
echo ================================================================
echo.
echo 1. Deploy (Build + Start)
echo 2. Start Services
echo 3. Stop Services
echo 4. Restart Services
echo 5. Check Health
echo 6. Show Logs
echo 7. Show URLs
echo 8. Cleanup (Remove all data)
echo 9. Exit
echo.
set /p choice="Select an option (1-9): "

if "%choice%"=="1" (
    call :check_prerequisites
    call :create_directories
    call :generate_env_files
    call :build_services
    call :start_services
    call :check_health
    call :show_urls
    goto :show_menu
) else if "%choice%"=="2" (
    call :start_services
    call :check_health
    call :show_urls
    goto :show_menu
) else if "%choice%"=="3" (
    call :stop_services
    goto :show_menu
) else if "%choice%"=="4" (
    call :stop_services
    timeout /t 5 /nobreak >nul
    call :start_services
    call :check_health
    call :show_urls
    goto :show_menu
) else if "%choice%"=="5" (
    call :check_health
    goto :show_menu
) else if "%choice%"=="6" (
    call :show_logs
    goto :show_menu
) else if "%choice%"=="7" (
    call :show_urls
    goto :show_menu
) else if "%choice%"=="8" (
    call :cleanup
    goto :show_menu
) else if "%choice%"=="9" (
    call :log_info "Goodbye!"
    exit /b 0
) else (
    call :log_error "Invalid option. Please try again."
    goto :show_menu
)

REM Main execution
:main
if "%1"=="deploy" (
    call :check_prerequisites
    call :create_directories
    call :generate_env_files
    call :build_services
    call :start_services
    call :check_health
    call :show_urls
) else if "%1"=="start" (
    call :start_services
    call :check_health
    call :show_urls
) else if "%1"=="stop" (
    call :stop_services
) else if "%1"=="restart" (
    call :stop_services
    timeout /t 5 /nobreak >nul
    call :start_services
    call :check_health
    call :show_urls
) else if "%1"=="health" (
    call :check_health
) else if "%1"=="logs" (
    call :show_logs
) else if "%1"=="urls" (
    call :show_urls
) else if "%1"=="cleanup" (
    call :cleanup
) else if "%1"=="menu" (
    goto :show_menu
) else (
    echo Usage: %0 {deploy^|start^|stop^|restart^|health^|logs^|urls^|cleanup^|menu}
    echo.
    echo Commands:
    echo   deploy   - Full deployment (build + start + health check)
    echo   start    - Start all services
    echo   stop     - Stop all services
    echo   restart  - Restart all services
    echo   health   - Check service health
    echo   logs     - Show service logs
    echo   urls     - Show service URLs
    echo   cleanup  - Remove all data and containers
    echo   menu     - Interactive menu
    exit /b 1
)

REM Run main function with all arguments
call :main %*
