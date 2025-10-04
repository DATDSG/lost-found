# PowerShell Commands for Lost & Found Project
# Use this in Windows Terminal with PowerShell

# =============================================================================
# STEP-BY-STEP STARTUP GUIDE FOR WINDOWS TERMINAL
# =============================================================================

# Open Windows Terminal
# Press Win + R, type "wt" and press Enter
# Or search for "Windows Terminal" in Start Menu

# =============================================================================
# 1. NAVIGATE TO PROJECT
# =============================================================================
Set-Location "c:\Users\td123\OneDrive\Documents\GitHub\lost-found"

# Verify you're in the right place
Get-ChildItem | Select-Object Name

# =============================================================================
# 2. SETUP ENVIRONMENT
# =============================================================================
# Check if .env file exists
Test-Path ".env"

# Copy environment file if it doesn't exist
if (!(Test-Path ".env")) {
    Copy-Item ".env.local" ".env"
    Write-Host "Environment file created from .env.local"
} else {
    Write-Host ".env file already exists"
}

# =============================================================================
# 3. CHECK DOCKER STATUS
# =============================================================================
# Verify Docker is installed and running
docker --version
docker-compose --version

# Check if Docker Desktop is running
docker info

# If Docker is not running, start Docker Desktop first
# Then run: docker info

# =============================================================================
# 4. NAVIGATE TO DEPLOYMENT DIRECTORY
# =============================================================================
Set-Location "deployment"

# List available docker-compose files
Get-ChildItem "docker-compose*.yml" | Select-Object Name

# =============================================================================
# 5. START SERVICES (CHOOSE ONE OPTION)
# =============================================================================

# OPTION A: MINIMAL SETUP (Recommended for first try)
# This starts only Database + Redis + Basic API
docker-compose -f docker-compose-minimal.yml up --build

# To run in background (detached mode):
# docker-compose -f docker-compose-minimal.yml up -d --build

# OPTION B: SIMPLE SETUP (With NLP & Vision)
# docker-compose -f docker-compose-simple.yml up --build

# OPTION C: FULL SETUP (All services)
# docker-compose -f docker-compose-local.yml up --build

# =============================================================================
# 6. VERIFY SERVICES ARE RUNNING (Open new PowerShell tab)
# =============================================================================
# Check running containers
docker ps

# Test API health
Invoke-RestMethod -Uri "http://localhost:8000/health" -Method Get

# Open API documentation in browser
Start-Process "http://localhost:8000/docs"

# =============================================================================
# 7. TEST DATABASE CONNECTION
# =============================================================================
# Connect to PostgreSQL
docker exec -it lf_database_minimal psql -U lostfound -d lostfound

# Inside PostgreSQL, run these commands:
# \dt          -- List tables
# \l           -- List databases
# SELECT version();  -- Check version
# \q           -- Quit

# =============================================================================
# 8. STOP SERVICES (When done)
# =============================================================================
# Stop all services (run in deployment directory)
docker-compose -f docker-compose-minimal.yml down

# Stop and remove data (clean restart)
docker-compose -f docker-compose-minimal.yml down -v

# =============================================================================
# TROUBLESHOOTING COMMANDS
# =============================================================================

# Check port usage
netstat -an | Select-String ":5432"  # PostgreSQL
netstat -an | Select-String ":8000"  # API

# View container logs
docker-compose -f docker-compose-minimal.yml logs
docker-compose -f docker-compose-minimal.yml logs api

# Restart specific service
docker-compose -f docker-compose-minimal.yml restart api

# Clean up Docker resources
docker container prune -f
docker image prune -f

# =============================================================================
# QUICK COMMANDS SUMMARY
# =============================================================================

# Complete startup sequence (copy and paste one by one):
# Set-Location "c:\Users\td123\OneDrive\Documents\GitHub\lost-found"
# Copy-Item ".env.local" ".env" -Force
# Set-Location "deployment"  
# docker-compose -f docker-compose-minimal.yml up --build

# Quick test (in new terminal):
# Invoke-RestMethod -Uri "http://localhost:8000/health"

# Quick stop:
# docker-compose -f docker-compose-minimal.yml down