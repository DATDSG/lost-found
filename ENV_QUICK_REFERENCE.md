# 🚀 Environment Files - Quick Reference

## 📁 File Structure (Standardized)

```
lost-found/
├── infra/compose/
│   ├── .env.example          ⭐ PRIMARY (140+ lines) - Docker Compose
│   └── .env                  ✅ Copy from example
│
├── services/
│   ├── api/
│   │   ├── .env.example      🔧 Standalone API dev (55 lines)
│   │   └── .env              ✅ Copy from example
│   ├── nlp/
│   │   └── .env.example      🔧 Standalone NLP dev (35 lines)
│   └── vision/
│       └── .env.example      🔧 Standalone Vision dev (35 lines)
│
└── apps/
    └── admin/
        ├── .env.example      🎨 Frontend dev (10 lines)
        └── .env.local        🔵 User override (optional)
```

---

## ⚡ Quick Start (3 Steps)

### 1️⃣ Docker Compose (Recommended)

```powershell
cd infra\compose
Copy-Item ".env.example" ".env"
docker-compose up -d
```

✅ **That's it!** All services will start with default configuration.

---

### 2️⃣ Update Critical Secrets (Recommended for Production)

Edit `infra/compose/.env`:

```bash
# Line 24 - Generate new JWT secret (64 chars)
JWT_SECRET=<your-64-char-hex-string>

# Line 29 - Generate new session secret (64 chars)
ADMIN_SESSION_SECRET=<your-64-char-hex-string>

# Line 18 - Change Redis password
REDIS_PASSWORD=<your-strong-password>

# Line 77 - Change Grafana password
GRAFANA_ADMIN_PASSWORD=<your-grafana-password>
```

**Generate secrets**:

```powershell
-join ((48..57) + (97..122) | Get-Random -Count 64 | ForEach-Object {[char]$_})
```

---

### 3️⃣ Verify Services

```powershell
# Check all services are running
docker-compose ps

# Test API
curl http://localhost:8000/health

# Open Grafana
Start http://localhost:3000
```

---

## 📋 Configuration Overview

### ⭐ Primary File: `infra/compose/.env`

| Section        | Variables | Keep As-Is? | Action Required         |
| -------------- | --------- | ----------- | ----------------------- |
| **PostgreSQL** | 5         | ✅ YES      | None                    |
| **Redis**      | 5         | ⚠️ NO       | Change password         |
| **JWT**        | 5         | ⚠️ NO       | Generate new secrets    |
| **Services**   | 6         | ✅ YES      | None                    |
| **Matching**   | 8         | ✅ YES      | Optional tuning         |
| **Monitoring** | 7         | ⚠️ NO       | Change Grafana password |
| **Features**   | 4         | ✅ YES      | Optional enable/disable |

---

## 🔑 Critical Variables Reference

### Keep As-Is (PostgreSQL)

```bash
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=lostfound
POSTGRES_HOST=host.docker.internal
POSTGRES_PORT=5432
```

✅ **Don't change** - Already configured correctly

---

### ⚠️ Must Change (Security)

```bash
# 1. JWT Secret (Line 24)
JWT_SECRET=a7f9e2b8c4d1f6a3e8b2c7d9f4e1a6b3...
# Generate: -join ((48..57) + (97..122) | Get-Random -Count 64 | ForEach-Object {[char]$_})

# 2. Session Secret (Line 29)
ADMIN_SESSION_SECRET=f3e8d1c9b7a2f6e4d8c3b1a9f7e2d6c4...
# Generate: -join ((48..57) + (97..122) | Get-Random -Count 64 | ForEach-Object {[char]$_})

# 3. Redis Password (Line 18)
REDIS_PASSWORD=LF_Redis_2025_Pass!
# Change to your own strong password

# 4. Grafana Password (Line 77)
GRAFANA_ADMIN_PASSWORD=LF_Grafana_Admin_2025!
# Change from default
```

---

## 🎯 Common Scenarios

### Scenario 1: Full Stack with Docker

```powershell
cd infra\compose
Copy-Item ".env.example" ".env"
docker-compose up -d
```

**Uses**: `infra/compose/.env` only  
**Time**: 2 minutes

---

### Scenario 2: Frontend Development

```powershell
# Start backend
cd infra\compose
docker-compose up -d

# Start frontend
cd ..\..\apps\admin
npm run dev
```

**Uses**: `infra/compose/.env` + auto-loads `.env.local`  
**Time**: 3 minutes

---

### Scenario 3: API Development Only

```powershell
# Start database & redis
cd infra\compose
docker-compose up -d db redis

# Run API standalone
cd ..\..\services\api
Copy-Item ".env.example" ".env"
uvicorn app.main:app --reload
```

**Uses**: `services/api/.env`  
**Time**: 3 minutes

---

## 🔍 Verification Commands

```powershell
# Check services
docker-compose ps

# Check database
docker exec -it lost-found-db psql -U postgres -d lostfound -c "\dt"

# Test API
curl http://localhost:8000/health

# Test NLP
curl http://localhost:8001/health

# Test Vision
curl http://localhost:8002/health

# Open Swagger
Start http://localhost:8000/docs

# Open Grafana
Start http://localhost:3000
```

---

## 🐛 Quick Troubleshooting

| Problem                       | Solution                                    |
| ----------------------------- | ------------------------------------------- |
| **Services won't start**      | Check `.env` exists in `infra/compose/`     |
| **Database connection fails** | Verify `POSTGRES_HOST=host.docker.internal` |
| **CORS errors**               | Add frontend URL to `CORS_ORIGINS`          |
| **JWT validation fails**      | Ensure `JWT_SECRET` is same across services |
| **Redis connection fails**    | Check `REDIS_PASSWORD` matches in URL       |

---

## 📚 Documentation Files

| File                            | Purpose          | Lines |
| ------------------------------- | ---------------- | ----- |
| **ENV_CONFIGURATION_README.md** | Complete guide   | 400+  |
| **ENV_CLEANUP_SUMMARY.md**      | What was changed | 300+  |
| **ENV_QUICK_REFERENCE.md**      | This file        | 200+  |

---

## ✅ Checklist

### Before First Run

- [ ] Copied `infra/compose/.env.example` to `infra/compose/.env`
- [ ] Optionally generated new JWT secrets
- [ ] Optionally changed Redis password
- [ ] Optionally changed Grafana password
- [ ] Added frontend URLs to CORS if needed

### After First Run

- [ ] All 10 services are healthy (`docker-compose ps`)
- [ ] Database has 11 tables (`\dt` in psql)
- [ ] API responds at http://localhost:8000/health
- [ ] Swagger UI accessible at http://localhost:8000/docs
- [ ] Grafana accessible at http://localhost:3000

---

## 🎉 Summary

**Total `.env` files**: 5  
**Required files**: 1 (`infra/compose/.env`)  
**Optional files**: 4 (service-specific development)

**PostgreSQL**: ✅ Keep as-is (`postgres/postgres`)  
**Redis**: ⚠️ Change password recommended  
**JWT**: ⚠️ Generate new secrets recommended  
**Grafana**: ⚠️ Change password recommended

**Status**: ✅ Clean, standardized, production-ready  
**Last Updated**: October 8, 2025

---

## 🔗 Quick Links

- **Main Config**: `infra/compose/.env.example`
- **Full Guide**: `ENV_CONFIGURATION_README.md`
- **Summary**: `ENV_CLEANUP_SUMMARY.md`
- **API Docs**: http://localhost:8000/docs
- **Monitoring**: http://localhost:3000
