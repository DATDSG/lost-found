#!/bin/bash

# ================================================================
# Lost & Found Deployment Script
# ================================================================
# Comprehensive deployment script for the Lost & Found application
# Supports both local and server deployment configurations
# ================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="lost-found"
COMPOSE_FILE="infra/compose/docker-compose.yml"
ENV_FILE="infra/compose/env.development"
SERVER_IP="172.104.40.189"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Create necessary directories
create_directories() {
    log_info "Creating necessary directories..."
    
    mkdir -p infra/compose/nginx/conf.d
    mkdir -p infra/compose/pgadmin
    mkdir -p infra/compose/init
    mkdir -p logs
    mkdir -p data
    
    log_success "Directories created"
}

# Generate environment files
generate_env_files() {
    log_info "Generating environment files..."
    
    # Development environment
    cat > infra/compose/env.development << EOF
# ================================================================
# Lost & Found - Development Environment Configuration
# ================================================================

# Environment
ENVIRONMENT=development
NODE_ENV=development
DEBUG=true

# Database Configuration
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=lostfound
DB_PORT=5433
DB_POOL_SIZE=10
DB_MAX_OVERFLOW=20
DB_POOL_TIMEOUT=30
DB_ECHO=false

# Redis Configuration
REDIS_PASSWORD=LF_Redis_2025_Pass!
REDIS_PORT=6379
REDIS_MAX_CONNECTIONS=20

# MinIO Configuration
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin123
MINIO_PORT=9000
MINIO_CONSOLE_PORT=9001

# JWT Configuration
JWT_SECRET_KEY=super-secret-jwt-key-change-me-in-production
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30

# Service Ports
API_PORT=8000
NLP_PORT=8001
VISION_PORT=8002
ADMIN_PORT=3000
NGINX_PORT=8080
PGADMIN_PORT=5050

# pgAdmin Configuration
PGADMIN_EMAIL=postgres
PGADMIN_PASSWORD=postgres

# CORS Configuration
CORS_ORIGINS=http://localhost:3000,http://localhost:8080,http://admin:3000,http://172.104.40.189:3000,http://172.104.40.189:8080,http://172.104.40.189:8000,http://172.104.40.189:8001,http://172.104.40.189:8002

# Application Settings
LOG_LEVEL=INFO
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS_PER_MINUTE=60
METRICS_ENABLED=true

# Domain-specific Settings
REPORTS_PER_PAGE=20
MATCHES_PER_PAGE=20
MAX_FILE_SIZE=10485760
ALLOWED_FILE_TYPES=image/jpeg,image/png,image/webp

# NLP Settings
SIMILARITY_THRESHOLD=0.7
FUZZY_MATCH_THRESHOLD=80
MAX_MATCHES=10
CACHE_TTL=3600
WORKER_CONCURRENCY=4
MAX_TEXT_LENGTH=10000

# Vision Settings
HASH_THRESHOLD_SIMILAR=10
HASH_THRESHOLD_MATCH=5
MAX_IMAGE_SIZE=10485760
MAX_IMAGE_DIMENSION=4096
EOF

    # Production environment
    cat > infra/compose/env.production << EOF
# ================================================================
# Lost & Found - Production Environment Configuration
# ================================================================

# Environment
ENVIRONMENT=production
NODE_ENV=production
DEBUG=false

# Database Configuration
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=lostfound
DB_PORT=5433
DB_POOL_SIZE=20
DB_MAX_OVERFLOW=40
DB_POOL_TIMEOUT=30
DB_ECHO=false

# Redis Configuration
REDIS_PASSWORD=LF_Redis_2025_Pass!
REDIS_PORT=6379
REDIS_MAX_CONNECTIONS=50

# MinIO Configuration
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin123
MINIO_PORT=9000
MINIO_CONSOLE_PORT=9001

# JWT Configuration
JWT_SECRET_KEY=super-secret-jwt-key-change-me-in-production
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30

# Service Ports
API_PORT=8000
NLP_PORT=8001
VISION_PORT=8002
ADMIN_PORT=3000
NGINX_PORT=8080
PGADMIN_PORT=5050

# pgAdmin Configuration
PGADMIN_EMAIL=postgres
PGADMIN_PASSWORD=postgres

# CORS Configuration
CORS_ORIGINS=http://localhost:3000,http://localhost:8080,http://admin:3000,http://172.104.40.189:3000,http://172.104.40.189:8080,http://172.104.40.189:8000,http://172.104.40.189:8001,http://172.104.40.189:8002

# Application Settings
LOG_LEVEL=WARNING
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS_PER_MINUTE=100
METRICS_ENABLED=true

# Domain-specific Settings
REPORTS_PER_PAGE=20
MATCHES_PER_PAGE=20
MAX_FILE_SIZE=10485760
ALLOWED_FILE_TYPES=image/jpeg,image/png,image/webp

# NLP Settings
SIMILARITY_THRESHOLD=0.7
FUZZY_MATCH_THRESHOLD=80
MAX_MATCHES=10
CACHE_TTL=3600
WORKER_CONCURRENCY=8
MAX_TEXT_LENGTH=10000

# Vision Settings
HASH_THRESHOLD_SIMILAR=10
HASH_THRESHOLD_MATCH=5
MAX_IMAGE_SIZE=10485760
MAX_IMAGE_DIMENSION=4096
EOF

    log_success "Environment files generated"
}

# Build services
build_services() {
    log_info "Building services..."
    
    # Use docker-compose or docker compose based on availability
    if command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    else
        COMPOSE_CMD="docker compose"
    fi
    
    # Build all services
    $COMPOSE_CMD -f $COMPOSE_FILE --env-file $ENV_FILE build --parallel
    
    log_success "Services built successfully"
}

# Start services
start_services() {
    log_info "Starting services..."
    
    # Use docker-compose or docker compose based on availability
    if command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    else
        COMPOSE_CMD="docker compose"
    fi
    
    # Start services in dependency order
    $COMPOSE_CMD -f $COMPOSE_FILE --env-file $ENV_FILE up -d db redis minio
    
    log_info "Waiting for infrastructure services to be ready..."
    sleep 30
    
    $COMPOSE_CMD -f $COMPOSE_FILE --env-file $ENV_FILE up -d nlp vision
    
    log_info "Waiting for ML services to be ready..."
    sleep 30
    
    $COMPOSE_CMD -f $COMPOSE_FILE --env-file $ENV_FILE up -d api worker
    
    log_info "Waiting for API service to be ready..."
    sleep 30
    
    $COMPOSE_CMD -f $COMPOSE_FILE --env-file $ENV_FILE up -d admin nginx pgadmin
    
    log_success "All services started successfully"
}

# Check service health
check_health() {
    log_info "Checking service health..."
    
    # Check API service
    if curl -f http://localhost:8000/v1/health &> /dev/null; then
        log_success "API service is healthy"
    else
        log_warning "API service health check failed"
    fi
    
    # Check NLP service
    if curl -f http://localhost:8001/health &> /dev/null; then
        log_success "NLP service is healthy"
    else
        log_warning "NLP service health check failed"
    fi
    
    # Check Vision service
    if curl -f http://localhost:8002/health &> /dev/null; then
        log_success "Vision service is healthy"
    else
        log_warning "Vision service health check failed"
    fi
    
    # Check Admin panel
    if curl -f http://localhost:3000/api/health &> /dev/null; then
        log_success "Admin panel is healthy"
    else
        log_warning "Admin panel health check failed"
    fi
    
    # Check Nginx
    if curl -f http://localhost:8080/health &> /dev/null; then
        log_success "Nginx is healthy"
    else
        log_warning "Nginx health check failed"
    fi
}

# Show service URLs
show_urls() {
    log_info "Service URLs:"
    echo ""
    echo "🌐 Web Services:"
    echo "  Admin Panel:     http://localhost:3000"
    echo "  Nginx Proxy:      http://localhost:8080"
    echo "  pgAdmin:         http://localhost:5050"
    echo ""
    echo "🔧 API Services:"
    echo "  API Service:     http://localhost:8000"
    echo "  NLP Service:     http://localhost:8001"
    echo "  Vision Service:  http://localhost:8002"
    echo ""
    echo "🗄️  Infrastructure:"
    echo "  PostgreSQL:      localhost:5433"
    echo "  Redis:           localhost:6379"
    echo "  MinIO:           http://localhost:9000"
    echo "  MinIO Console:   http://localhost:9001"
    echo ""
    echo "🌍 Server Access (172.104.40.189):"
    echo "  Admin Panel:     http://172.104.40.189:3000"
    echo "  API Service:     http://172.104.40.189:8000"
    echo "  Nginx Proxy:     http://172.104.40.189:8080"
    echo ""
    echo "🔑 Default Credentials:"
    echo "  Database:        postgres / postgres"
    echo "  pgAdmin:         postgres / postgres"
    echo "  MinIO:           minioadmin / minioadmin123"
    echo "  Redis:           LF_Redis_2025_Pass!"
}

# Stop services
stop_services() {
    log_info "Stopping services..."
    
    # Use docker-compose or docker compose based on availability
    if command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    else
        COMPOSE_CMD="docker compose"
    fi
    
    $COMPOSE_CMD -f $COMPOSE_FILE --env-file $ENV_FILE down
    
    log_success "Services stopped"
}

# Clean up
cleanup() {
    log_info "Cleaning up..."
    
    # Use docker-compose or docker compose based on availability
    if command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    else
        COMPOSE_CMD="docker compose"
    fi
    
    $COMPOSE_CMD -f $COMPOSE_FILE --env-file $ENV_FILE down -v --remove-orphans
    docker system prune -f
    
    log_success "Cleanup completed"
}

# Show logs
show_logs() {
    log_info "Showing service logs..."
    
    # Use docker-compose or docker compose based on availability
    if command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    else
        COMPOSE_CMD="docker compose"
    fi
    
    $COMPOSE_CMD -f $COMPOSE_FILE --env-file $ENV_FILE logs -f
}

# Main menu
show_menu() {
    echo ""
    echo "================================================================"
    echo "Lost & Found Deployment Script"
    echo "================================================================"
    echo ""
    echo "1. Deploy (Build + Start)"
    echo "2. Start Services"
    echo "3. Stop Services"
    echo "4. Restart Services"
    echo "5. Check Health"
    echo "6. Show Logs"
    echo "7. Show URLs"
    echo "8. Cleanup (Remove all data)"
    echo "9. Exit"
    echo ""
    read -p "Select an option (1-9): " choice
}

# Main execution
main() {
    case $1 in
        "deploy")
            check_prerequisites
            create_directories
            generate_env_files
            build_services
            start_services
            check_health
            show_urls
            ;;
        "start")
            start_services
            check_health
            show_urls
            ;;
        "stop")
            stop_services
            ;;
        "restart")
            stop_services
            sleep 5
            start_services
            check_health
            show_urls
            ;;
        "health")
            check_health
            ;;
        "logs")
            show_logs
            ;;
        "urls")
            show_urls
            ;;
        "cleanup")
            cleanup
            ;;
        "menu")
            while true; do
                show_menu
                case $choice in
                    1)
                        check_prerequisites
                        create_directories
                        generate_env_files
                        build_services
                        start_services
                        check_health
                        show_urls
                        ;;
                    2)
                        start_services
                        check_health
                        show_urls
                        ;;
                    3)
                        stop_services
                        ;;
                    4)
                        stop_services
                        sleep 5
                        start_services
                        check_health
                        show_urls
                        ;;
                    5)
                        check_health
                        ;;
                    6)
                        show_logs
                        ;;
                    7)
                        show_urls
                        ;;
                    8)
                        cleanup
                        ;;
                    9)
                        log_info "Goodbye!"
                        exit 0
                        ;;
                    *)
                        log_error "Invalid option. Please try again."
                        ;;
                esac
            done
            ;;
        *)
            echo "Usage: $0 {deploy|start|stop|restart|health|logs|urls|cleanup|menu}"
            echo ""
            echo "Commands:"
            echo "  deploy   - Full deployment (build + start + health check)"
            echo "  start    - Start all services"
            echo "  stop     - Stop all services"
            echo "  restart  - Restart all services"
            echo "  health   - Check service health"
            echo "  logs     - Show service logs"
            echo "  urls     - Show service URLs"
            echo "  cleanup  - Remove all data and containers"
            echo "  menu     - Interactive menu"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
