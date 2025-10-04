# Manual Terminal Commands for Lost & Found Project

This guide provides all the terminal commands needed to run the Lost & Found project manually using Windows Terminal, PowerShell, or Command Prompt.

## 🔧 Prerequisites Check

First, verify you have the required tools installed:

```cmd
# Check Docker
docker --version
docker-compose --version

# Check if Docker Desktop is running
docker info
```

If Docker is not running, start Docker Desktop first.

## 📁 Navigation Commands

```cmd
# Navigate to project directory
cd c:\Users\td123\OneDrive\Documents\GitHub\lost-found

# List files to confirm you're in the right place
dir

# You should see files like: docker-compose.yml, package.json, README.md, etc.
```

## 🔄 Environment Setup Commands

### Step 1: Create Environment File

```cmd
# Check if .env file exists
dir .env*

# If .env doesn't exist, copy from the local template
copy .env.local .env

# Verify the file was created
dir .env
```

### Step 2: Navigate to Deployment Directory

```cmd
# Change to deployment directory
cd deployment

# List available docker-compose files
dir docker-compose*.yml
```

## 🚀 Startup Commands (Choose One Option)

### Option 1: Minimal Setup (Recommended First)

```cmd
# From the deployment directory
docker-compose -f docker-compose-minimal.yml up --build

# Alternative: Run in detached mode (background)
docker-compose -f docker-compose-minimal.yml up -d --build
```

### Option 2: Simple Setup (With NLP & Vision)

```cmd
# From the deployment directory
docker-compose -f docker-compose-simple.yml up --build

# Alternative: Run in detached mode
docker-compose -f docker-compose-simple.yml up -d --build
```

### Option 3: Full Setup (All Services)

```cmd
# From the deployment directory
docker-compose -f docker-compose-local.yml up --build

# Alternative: Run in detached mode
docker-compose -f docker-compose-local.yml up -d --build
```

## 📊 Monitoring Commands

### Check Service Status

```cmd
# View running containers
docker ps

# View all containers (including stopped)
docker ps -a

# Check specific container logs
docker logs lf_database_minimal
docker logs lf_api_minimal
docker logs lf_redis_minimal
```

### Check Container Health

```cmd
# Check database health
docker exec lf_database_minimal pg_isready -U lostfound -d lostfound

# Test Redis connection
docker exec lf_redis_minimal redis-cli ping

# Check API health (once running)
curl http://localhost:8000/health
```

## 🧪 Testing Commands

### Basic API Tests

```cmd
# Test health endpoint
curl http://localhost:8000/health

# Test API documentation (opens in browser)
start http://localhost:8000/docs

# Create a test item (POST request)
curl -X POST "http://localhost:8000/api/v1/items" ^
  -H "Content-Type: application/json" ^
  -d "{\"title\":\"Test Item\",\"description\":\"Testing API\",\"category\":\"electronics\",\"item_type\":\"lost\"}"
```

### Database Connection Test

```cmd
# Connect to PostgreSQL database
docker exec -it lf_database_minimal psql -U lostfound -d lostfound

# Once connected, run these SQL commands:
# \dt                    -- List tables
# \l                     -- List databases
# SELECT version();      -- Check PostgreSQL version
# \q                     -- Quit
```

## 🛠️ Management Commands

### Start/Stop Services

```cmd
# Stop all services (from deployment directory)
docker-compose -f docker-compose-minimal.yml down

# Stop and remove volumes (clean restart)
docker-compose -f docker-compose-minimal.yml down -v

# Start existing services (without rebuild)
docker-compose -f docker-compose-minimal.yml up

# Start specific service only
docker-compose -f docker-compose-minimal.yml up database
```

### View Logs

```cmd
# View logs for all services
docker-compose -f docker-compose-minimal.yml logs

# View logs for specific service
docker-compose -f docker-compose-minimal.yml logs api

# Follow logs in real-time
docker-compose -f docker-compose-minimal.yml logs -f api
```

### Resource Cleanup

```cmd
# Remove stopped containers
docker container prune

# Remove unused images
docker image prune

# Remove unused volumes (BE CAREFUL - this deletes data)
docker volume prune

# Remove everything (DANGEROUS - only if you want to start fresh)
docker system prune -a
```

## 🐛 Troubleshooting Commands

### Common Dependency Issues

```cmd
# If you get "ModuleNotFoundError: No module named 'decouple'"
# This means the requirements.txt was missing python-decouple
# The containers need to be rebuilt after fixing dependencies:

# Stop services
docker-compose -f docker-compose-minimal.yml down

# Remove old images to force rebuild
docker-compose -f docker-compose-minimal.yml down --rmi all

# Rebuild and start (this will use updated requirements.txt)
docker-compose -f docker-compose-minimal.yml up --build
```

### Port Conflicts

```cmd
# Check what's using port 5432 (PostgreSQL)
netstat -an | findstr ":5432"

# Check what's using port 8000 (API)
netstat -an | findstr ":8000"

# Kill process using a port (replace PID with actual process ID)
taskkill /PID [process_id] /F
```

### Docker Issues

```cmd
# Restart Docker Desktop (if needed)
# Close Docker Desktop, then restart it

# Check Docker disk usage
docker system df

# Check Docker daemon status
docker version
```

### Container Debugging

```cmd
# Execute shell inside running container
docker exec -it lf_api_minimal /bin/bash

# View container environment variables
docker exec lf_api_minimal env

# Copy files from container to local machine
docker cp lf_api_minimal:/app/logs ./logs
```

## 📋 Step-by-Step Startup Checklist

### For Minimal Setup:

1. **Open Windows Terminal**
2. **Navigate to project:**

   ```cmd
   cd c:\Users\td123\OneDrive\Documents\GitHub\lost-found
   ```

3. **Setup environment:**

   ```cmd
   copy .env.local .env
   ```

4. **Go to deployment directory:**

   ```cmd
   cd deployment
   ```

5. **Start services:**

   ```cmd
   docker-compose -f docker-compose-minimal.yml up --build
   ```

6. **In a new terminal tab, test the API:**

   ```cmd
   curl http://localhost:8000/health
   ```

7. **Open API documentation:**
   ```cmd
   start http://localhost:8000/docs
   ```

### Expected Output:

- Database container should show: `database system is ready to accept connections`
- Redis container should show: `Ready to accept connections`
- API container should show: `Uvicorn running on http://0.0.0.0:8000`

## 🌐 Access URLs

Once services are running:

- **API Documentation:** http://localhost:8000/docs
- **API Health Check:** http://localhost:8000/health
- **Database:** localhost:5432 (user: lostfound, password: lostfound)
- **Redis:** localhost:6379

## 📝 Common Commands Summary

```cmd
# Quick start (run these in order)
cd c:\Users\td123\OneDrive\Documents\GitHub\lost-found
copy .env.local .env
cd deployment
docker-compose -f docker-compose-minimal.yml up --build

# Quick stop
docker-compose -f docker-compose-minimal.yml down

# Quick restart
docker-compose -f docker-compose-minimal.yml down
docker-compose -f docker-compose-minimal.yml up --build

# Check status
docker ps
curl http://localhost:8000/health
```

## 🔍 What to Look For

### Success Indicators:

- No error messages in terminal output
- `curl http://localhost:8000/health` returns JSON response
- `docker ps` shows containers with "Up" status
- API docs accessible at http://localhost:8000/docs

### Failure Indicators:

- Container exits with error codes
- Port binding errors (port already in use)
- Database connection failures
- HTTP connection refused errors

Save this document and run commands one by one in Windows Terminal to avoid the immediate closing issue!
