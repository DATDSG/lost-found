# 🔧 Environment Configuration Guide

## Overview

This project uses **environment variables** for configuration. The main deployment method is **Docker Compose**, but individual services can also run standalone for development.

---

## 📁 Environment Files Structure

```
lost-found/
├── infra/compose/.env              ⭐ PRIMARY - Docker Compose deployment
├── services/
│   ├── api/.env                    🔧 Standalone API development
│   ├── nlp/.env                    🔧 Standalone NLP development
│   └── vision/.env                 🔧 Standalone Vision development
└── apps/
    └── admin/.env                  🎨 Frontend development
```

---

## 🚀 Quick Start (5 Minutes)

### For Docker Compose Deployment (Recommended)

```powershell
# 1. Navigate to compose directory
cd infra\compose

# 2. Copy environment file
Copy-Item ".env.example" ".env"

# 3. Generate secure secrets
-join ((48..57) + (97..122) | Get-Random -Count 64 | ForEach-Object {[char]$_})

# 4. Edit .env and update these critical values:
#    - JWT_SECRET (line 24)
#    - ADMIN_SESSION_SECRET (line 29)
#    - REDIS_PASSWORD (line 18)
#    - GRAFANA_ADMIN_PASSWORD (line 77)

# 5. Start all services
docker-compose up -d
```

### For Individual Service Development

```powershell
# API Service
cd services\api
Copy-Item ".env.example" ".env"
# Edit .env as needed

# NLP Service
cd services\nlp
Copy-Item ".env.example" ".env"

# Vision Service
cd services\vision
Copy-Item ".env.example" ".env"

# Admin Frontend
cd apps\admin
Copy-Item ".env.example" ".env"
```

---

## 📋 Environment Files Explained

### 1. **infra/compose/.env** (PRIMARY)

**Purpose**: Main configuration for Docker Compose deployment  
**Used by**: All services when running via `docker-compose up`

**Key Sections**:

- ✅ **PostgreSQL** (Keep as-is: `postgres/postgres@host.docker.internal`)
- 🔐 **Redis** (Password: `LF_Redis_2025_Pass!`)
- 🔑 **JWT Secrets** (64-char hex strings)
- 🌐 **Service URLs** (Internal Docker network)
- 📊 **Monitoring** (Grafana, Prometheus, Loki)
- ⚙️ **Matching Algorithm** (Weights and thresholds)
- 🚦 **Rate Limiting**
- 🎛️ **Feature Flags**

**Critical Variables to Change**:

```bash
JWT_SECRET=<generate-new>
ADMIN_SESSION_SECRET=<generate-new>
REDIS_PASSWORD=<your-password>
GRAFANA_ADMIN_PASSWORD=<your-password>
```

---

### 2. **services/api/.env**

**Purpose**: Standalone API development (without Docker Compose)  
**Used by**: Running API directly with `uvicorn` or `python`

**When to use**:

- Local development
- Testing API without containers
- Debugging with IDE

**Key Differences from Compose**:

- Database: `host.docker.internal` → `localhost` (if PostgreSQL runs locally)
- Services: `http://nlp:8001` → `http://localhost:8001`
- Redis: `redis://redis:6379` → `redis://localhost:6379`

---

### 3. **services/nlp/.env**

**Purpose**: Standalone NLP service development  
**Used by**: Running NLP service directly with `python`

**Key Configuration**:

```bash
MODEL_NAME=sentence-transformers/all-MiniLM-L6-v2
USE_GPU=false  # Set true if GPU available
REDIS_URL=redis://redis:6379/0
```

---

### 4. **services/vision/.env**

**Purpose**: Standalone Vision service development  
**Used by**: Running Vision service directly with `python`

**Key Configuration**:

```bash
YOLO_MODEL=yolov8n.pt
CLIP_MODEL=ViT-B/32
USE_GPU=false  # Set true if GPU available
ENABLE_OBJECT_DETECTION=true
```

---

### 5. **apps/admin/.env**

**Purpose**: Frontend (Vite React) development  
**Used by**: Running `npm run dev` in admin app

**Configuration**:

```bash
VITE_API_URL=http://localhost:8000/api
```

**For production**:

```bash
VITE_API_URL=https://api.yourdomain.com/api
```

---

## 🔐 Security Best Practices

### Generate Secure Secrets

```powershell
# PowerShell (64 characters)
-join ((48..57) + (97..122) | Get-Random -Count 64 | ForEach-Object {[char]$_})

# Bash (64 characters hex)
openssl rand -hex 32
```

### Critical Security Checklist

- [ ] Changed `JWT_SECRET` from default
- [ ] Changed `ADMIN_SESSION_SECRET` from default
- [ ] Changed `REDIS_PASSWORD` from default
- [ ] Changed `GRAFANA_ADMIN_PASSWORD` from default
- [ ] Never commit `.env` files to Git (already in `.gitignore`)
- [ ] Use HTTPS in production (`SESSION_COOKIE_SECURE=true`)
- [ ] Restrict `CORS_ORIGINS` to your actual domains

---

## 🗂️ Files Summary

| File                   | Purpose                   | When to Use                          | Required           |
| ---------------------- | ------------------------- | ------------------------------------ | ------------------ |
| **infra/compose/.env** | Docker Compose deployment | Production & development with Docker | ⭐ **YES**         |
| services/api/.env      | API standalone dev        | Testing API locally                  | Optional           |
| services/nlp/.env      | NLP standalone dev        | Testing NLP locally                  | Optional           |
| services/vision/.env   | Vision standalone dev     | Testing Vision locally               | Optional           |
| apps/admin/.env        | Frontend dev              | Frontend development                 | When developing UI |

---

## 🎯 Configuration by Scenario

### Scenario 1: Full Docker Compose Deployment (Recommended)

```powershell
cd infra\compose
Copy-Item ".env.example" ".env"
# Edit .env (update secrets)
docker-compose up -d
```

**Files needed**: `infra/compose/.env` only

---

### Scenario 2: API Development (Standalone)

```powershell
# Start PostgreSQL and Redis via Docker
cd infra\compose
docker-compose up -d db redis

# Run API standalone
cd ..\..\services\api
Copy-Item ".env.example" ".env"
# Edit .env (update DATABASE_URL to localhost if needed)
uvicorn app.main:app --reload
```

**Files needed**: `services/api/.env`

---

### Scenario 3: Frontend Development Only

```powershell
# Start backend via Docker Compose
cd infra\compose
docker-compose up -d

# Start frontend
cd ..\..\apps\admin
Copy-Item ".env.example" ".env"
npm install
npm run dev
```

**Files needed**: `infra/compose/.env` + `apps/admin/.env`

---

### Scenario 4: Full Stack Local Development

```powershell
# Backend with Docker
cd infra\compose
docker-compose up -d

# Frontend standalone
cd ..\..\apps\admin
npm run dev
```

**Files needed**: `infra/compose/.env` + `apps/admin/.env`

---

## 🔧 Configuration Variables Reference

### Database (Keep as-is)

```bash
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=lostfound
POSTGRES_HOST=host.docker.internal  # or 'db' in Docker
POSTGRES_PORT=5432
```

### Redis (Update password)

```bash
REDIS_HOST=redis  # or 'localhost' for standalone
REDIS_PORT=6379
REDIS_PASSWORD=LF_Redis_2025_Pass!  # ⚠️ CHANGE THIS
```

### JWT (Generate new)

```bash
JWT_SECRET=<64-char-hex>  # ⚠️ GENERATE NEW
JWT_ALGORITHM=HS256
ACCESS_TTL_MIN=60
REFRESH_TTL_DAYS=30
```

### Services

```bash
NLP_SERVICE_URL=http://nlp:8001    # Docker: nlp, Standalone: localhost
VISION_SERVICE_URL=http://vision:8002
API_BASE_URL=http://api:8000
```

### Matching Algorithm

```bash
MATCH_WEIGHT_TEXT=0.45    # Text similarity (45%)
MATCH_WEIGHT_IMAGE=0.35   # Image similarity (35%)
MATCH_WEIGHT_GEO=0.15     # Location (15%)
MATCH_WEIGHT_TIME=0.05    # Time proximity (5%)
MATCH_MIN_SCORE=0.65      # Minimum match threshold
```

### Monitoring

```bash
GRAFANA_ADMIN_PASSWORD=LF_Grafana_Admin_2025!  # ⚠️ CHANGE THIS
PROMETHEUS_RETENTION=15d
LOKI_RETENTION=30d
```

---

## 📊 Verification

### Check Environment is Loaded

```powershell
# In Docker Compose directory
cd infra\compose

# View resolved configuration
docker-compose config
```

### Test Database Connection

```powershell
docker exec -it lost-found-db psql -U postgres -d lostfound -c "\dt"
```

**Expected**: List of 11 tables

### Test Services

```powershell
# API Health
curl http://localhost:8000/health

# NLP Service
curl http://localhost:8001/health

# Vision Service
curl http://localhost:8002/health

# Grafana
Start http://localhost:3000
```

---

## 🐛 Troubleshooting

### Problem: Services can't connect to database

**Solution**: Check `POSTGRES_HOST`

- Docker Compose: `POSTGRES_HOST=db`
- Standalone: `POSTGRES_HOST=localhost` or `POSTGRES_HOST=host.docker.internal`

### Problem: CORS errors in frontend

**Solution**: Add frontend URL to `CORS_ORIGINS`

```bash
CORS_ORIGINS=http://localhost:5173,http://localhost:3000
```

### Problem: JWT validation fails

**Solution**: Ensure `JWT_SECRET` is the same across all services

### Problem: Redis connection failed

**Solution**: Check Redis password and URL format

```bash
# With password
REDIS_URL=redis://:LF_Redis_2025_Pass!@redis:6379/0

# Without password
REDIS_URL=redis://redis:6379/0
```

---

## 📦 .gitignore

All `.env` files are ignored (only `.env.example` is tracked):

```gitignore
# Environment files
.env
.env.local
.env.*.local
**/.env
!**/.env.example
```

---

## 🔄 Migration from Old Setup

If you have old `.env` files:

```powershell
# Backup old files
Copy-Item "infra\compose\.env" "infra\compose\.env.backup"

# Use new examples
Copy-Item "infra\compose\.env.example" "infra\compose\.env"

# Migrate critical values from backup
# - PostgreSQL credentials (keep as-is)
# - JWT secrets (or generate new)
# - External service credentials
```

---

## 📝 Summary

- **Primary file**: `infra/compose/.env` for Docker Compose deployment
- **Optional files**: Service-specific `.env` files for standalone development
- **Security**: Always change default secrets (JWT, Redis, Grafana)
- **Database**: Keep PostgreSQL credentials as-is (`postgres/postgres`)
- **CORS**: Add your frontend URLs to `CORS_ORIGINS`

---

**Status**: ✅ Environment configuration standardized  
**Last Updated**: October 8, 2025  
**Version**: 2.0.0
