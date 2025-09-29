# Lost & Found System - Development Commands

.PHONY: help install dev build test clean docker-up docker-down

# Default target
help:
	@echo "Lost & Found System - Available Commands:"
	@echo ""
	@echo "Setup Commands:"
	@echo "  install     - Install all dependencies"
	@echo "  install-web - Install web admin dependencies"
	@echo "  install-api - Install API dependencies"
	@echo "  install-mobile - Install mobile dependencies"
	@echo ""
	@echo "Development Commands:"
	@echo "  dev        - Start all development servers"
	@echo "  dev-web    - Start web admin development server"
	@echo "  dev-api    - Start API development server"
	@echo "  dev-nlp    - Start NLP service"
	@echo "  dev-vision - Start Vision service"
	@echo ""
	@echo "Build Commands:"
	@echo "  build      - Build all applications"
	@echo "  build-web  - Build web admin"
	@echo "  build-mobile - Build mobile app"
	@echo ""
	@echo "Test Commands:"
	@echo "  test       - Run all tests"
	@echo "  test-web   - Run web admin tests"
	@echo "  test-api   - Run API tests"
	@echo "  test-mobile - Run mobile tests"
	@echo ""
	@echo "Docker Commands:"
	@echo "  docker-up  - Start all services with Docker"
	@echo "  docker-down - Stop all Docker services"
	@echo "  docker-build - Build Docker images"
	@echo ""
	@echo "Configuration Commands:"
	@echo "  setup-env  - Copy all environment template files"
	@echo "  validate-config - Validate system configuration"
	@echo "  show-config - Show current configuration status"
	@echo ""
	@echo "Utility Commands:"
	@echo "  clean      - Clean build artifacts"
	@echo "  lint       - Run linting on all code"
	@echo "  format     - Format all code"

# Installation targets
install: install-web install-api install-mobile
	@echo "All dependencies installed successfully!"

install-web:
	@echo "Installing web admin dependencies..."
	cd frontend/web-admin && npm install

install-api:
	@echo "Installing API dependencies..."
	cd backend/api && pip install -r requirements.txt

install-mobile:
	@echo "Installing mobile dependencies..."
	cd frontend/mobile && flutter pub get

# Development targets
dev:
	@echo "Starting all development services..."
	npm run dev

dev-web:
	@echo "Starting web admin development server..."
	cd frontend/web-admin && npm run dev

dev-api:
	@echo "Starting API development server..."
	cd backend/api && uvicorn app.main:app --reload --port 8000

dev-nlp:
	@echo "Starting NLP service..."
	cd backend/nlp && python server/main.py

dev-vision:
	@echo "Starting Vision service..."
	cd backend/vision && python server/main.py

# Build targets
build: build-web build-mobile
	@echo "All applications built successfully!"

build-web:
	@echo "Building web admin..."
	cd frontend/web-admin && npm run build

build-mobile:
	@echo "Building mobile app..."
	cd frontend/mobile && flutter build apk --release

# Test targets
test: test-web test-api test-mobile
	@echo "All tests completed!"

test-web:
	@echo "Running web admin tests..."
	cd frontend/web-admin && npm test

test-api:
	@echo "Running API tests..."
	cd backend/api && pytest

test-mobile:
	@echo "Running mobile tests..."
	cd frontend/mobile && flutter test

# Docker targets
docker-up:
	@echo "Starting Docker services..."
	cd deployment && docker-compose up -d

docker-down:
	@echo "Stopping Docker services..."
	cd deployment && docker-compose down

docker-build:
	@echo "Building Docker images..."
	cd deployment && docker-compose build

# Utility targets
clean:
	@echo "Cleaning build artifacts..."
	rm -rf frontend/web-admin/.next
	rm -rf frontend/web-admin/out
	rm -rf frontend/mobile/build
	rm -rf backend/api/__pycache__
	rm -rf backend/api/**/__pycache__

lint:
	@echo "Running linting..."
	cd frontend/web-admin && npm run lint
	cd backend/api && flake8 .

format:
	@echo "Formatting code..."
	cd frontend/web-admin && npm run format
	cd backend/api && black .
	cd frontend/mobile && dart format .

# Database targets
db-migrate:
	@echo "Running database migrations..."
	cd backend/api && alembic upgrade head

db-seed:
	@echo "Seeding database with sample data..."
	cd backend/api && python -c "from app.db.init_db import init_db; init_db()"

# Configuration targets
setup-env:
	@echo "Setting up environment files..."
	@test -f .env || (cp .env.example .env && echo "Created .env")
	@test -f backend/api/.env || (cp backend/api/.env.example backend/api/.env && echo "Created backend/api/.env")
	@test -f backend/nlp/.env || (cp backend/nlp/.env.example backend/nlp/.env && echo "Created backend/nlp/.env")  
	@test -f backend/vision/.env || (cp backend/vision/.env.example backend/vision/.env && echo "Created backend/vision/.env")
	@test -f frontend/web-admin/.env || (cp frontend/web-admin/.env.example frontend/web-admin/.env && echo "Created frontend/web-admin/.env")
	@echo "Environment files created! Please edit them with your actual configuration values."
	@echo "See API_KEYS_GUIDE.md for detailed instructions."

validate-config:
	@echo "Validating system configuration..."
	python tools/validate_config.py

show-config:
	@echo "Current Configuration Status:"
	@echo "Environment files:"
	@test -f .env && echo "  ✅ .env" || echo "  ❌ .env (missing)"
	@test -f backend/api/.env && echo "  ✅ backend/api/.env" || echo "  ❌ backend/api/.env (missing)"
	@test -f backend/nlp/.env && echo "  ✅ backend/nlp/.env" || echo "  ❌ backend/nlp/.env (missing)"
	@test -f backend/vision/.env && echo "  ✅ backend/vision/.env" || echo "  ❌ backend/vision/.env (missing)"
	@test -f frontend/web-admin/.env && echo "  ✅ frontend/web-admin/.env" || echo "  ❌ frontend/web-admin/.env (missing)"
	@echo ""
	@echo "Run 'make setup-env' to create missing environment files"
	@echo "Run 'make validate-config' to test configuration"

# Analysis targets
analyze:
	@echo "Running match evaluation analysis..."
	cd tools && python evaluate_matches.py --limit 100