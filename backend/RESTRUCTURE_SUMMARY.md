# Lost & Found Backend - Restructured

This document describes the new consolidated backend structure implemented for improved maintainability and development velocity.

## 🎯 What Changed

### Major Improvements

1. ✅ **Health & Readiness Endpoints**: All services now expose `/healthz` (liveness) and `/readyz` (readiness) endpoints
2. ✅ **Shared Common Package**: `backend/common/` for reusable code across services
3. ✅ **Research Isolation**: All notebooks and experiments moved to `research/`
4. ✅ **Legacy Code Archived**: `backend/api/src/` archived to `research/legacy_src/`
5. ✅ **Consolidated Dependencies**: Root `pyproject.toml` with optional extras
6. ✅ **Build Optimization**: `.dockerignore` files reduce Docker context size
7. ✅ **Test Coverage**: Pytest suite for health endpoint behavior

### Directory Structure (New)

```
backend/
  common/                    # Shared internal package
    __init__.py
    health.py               # Readiness registry
    models/
      soft_delete.py        # Migrated from src/

  api/                      # Main API service
    .dockerignore
    Dockerfile
    requirements.txt
    app/
      main.py              # Updated with /healthz + /readyz
      api/                 # Route modules
      core/
      db/
      schemas/
      services/
      utils/
      workers/

  nlp/                      # NLP microservice
    .dockerignore
    Dockerfile
    requirements.txt
    server/
      main.py              # Updated with /healthz + /readyz + model tracking

  vision/                   # Vision microservice
    .dockerignore
    Dockerfile
    requirements.txt
    server/
      main.py              # Updated with /healthz + /readyz

  worker/                   # Background worker (Celery)
    .dockerignore
    Dockerfile
    requirements.txt
    worker/
      __init__.py
      jobs.py
      health.py            # Health helper functions

  base/                     # Shared Docker base image
    Dockerfile

research/                   # Experiments, notebooks, archived code
  notebooks/
    nlp/                   # Moved from backend/nlp/notebooks
    vision/                # Moved from backend/vision/notebooks
  experiments/             # Moved from backend/api/app/research
  legacy_src/              # Archived backend/api/src for reference

tests/                      # Test suite
  conftest.py
  test_health_endpoints.py
  README.md

pyproject.toml             # Consolidated dependency management
```

## 🚀 Quick Start

### Install Dependencies

For local development (all services):

```bash
pip install -e ".[all]"
```

For specific service development:

```bash
# API only
pip install -e ".[api,dev]"

# NLP only
pip install -e ".[nlp,dev]"

# Vision only
pip install -e ".[vision,dev]"

# Worker only
pip install -e ".[worker,dev]"
```

### Running Tests

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=backend --cov-report=html

# Skip integration tests (unit only)
pytest -m "not integration"
```

### Running Services Locally

Each service can run standalone for development:

```bash
# API service
cd backend/api
uvicorn app.main:app --reload --port 8000

# NLP service
cd backend/nlp
python server/main.py

# Vision service
cd backend/vision
python server/main.py

# Worker
cd backend/worker
celery -A worker.jobs worker --loglevel=info
```

### Docker Compose

```bash
# Build and start all services
docker compose -f deployment/docker-compose-local.yml up --build

# Start specific service
docker compose -f deployment/docker-compose-local.yml up api

# Health checks
curl http://localhost:8000/healthz
curl http://localhost:8000/readyz
curl http://localhost:8090/healthz
curl http://localhost:8090/readyz
curl http://localhost:8091/healthz
curl http://localhost:8091/readyz
```

## 📋 Health & Readiness Endpoints

### Standard Contract

All HTTP services now implement:

- **`GET /healthz`** - Liveness probe (returns `{"status": "ok"}`)
- **`GET /readyz`** - Readiness probe (checks dependencies, model loading, etc.)

### Service-Specific Readiness

#### API Service (`/readyz`)

```json
{
  "ready": true,
  "database": true,
  "app": "lost-found-api",
  "version": "2.0.0",
  "features": {
    "nlp_enabled": true,
    "cv_enabled": true,
    "languages": ["en", "si", "ta"]
  }
}
```

#### NLP Service (`/readyz`)

```json
{
  "ready": true,
  "embedding_model_loaded": true,
  "ner_model_loaded": true
}
```

#### Vision Service (`/readyz`)

```json
{
  "ready": true,
  "model_version": "phash-v1"
}
```

#### Worker Service

Worker uses helper functions (no HTTP server):

```python
from backend.worker.worker.health import worker_health, worker_readyz
```

## 🔧 Common Package

The `backend/common/` package provides shared utilities:

### Readiness Registry (`backend.common.health`)

```python
from backend.common.health import readiness

# Register a check
def check_database():
    # ... perform check
    return True

readiness.register("database", check_database)

# Get status
status = readiness.status()
# Returns: {"database": {"ok": True}, "overall_ok": True}
```

### Soft Delete Models (`backend.common.models.soft_delete`)

Mixins for SQLAlchemy models (migrated from legacy src):

```python
from backend.common.models.soft_delete import SoftDeleteMixin, AuditLogMixin

class MyModel(Base, SoftDeleteMixin):
    # Adds: deleted_at, is_deleted fields + soft delete behavior
    pass
```

## 📦 Dependency Management

### Core Philosophy

- **Minimal base**: FastAPI, Uvicorn, Pydantic in core dependencies
- **Optional extras**: Install only what each service needs
- **Lock files**: Each service keeps `requirements.txt` for Docker builds
- **pyproject.toml**: Central source of truth for dependency versions

### Updating Dependencies

1. Edit `pyproject.toml` extras
2. Regenerate service requirements:
   ```bash
   pip install -e ".[api]"
   pip freeze > backend/api/requirements.txt
   ```
3. Test builds

## 🐳 Docker Optimizations

### .dockerignore Benefits

- **Smaller contexts**: Excludes notebooks, tests, docs, cache dirs
- **Faster builds**: Less data transferred to Docker daemon
- **Cleaner images**: No leaked secrets or dev files

### Typical Size Reduction

- Before: ~500MB context
- After: ~50MB context (10x improvement)

## 🧪 Testing Strategy

### Unit Tests

Fast, isolated tests of individual functions/endpoints:

```bash
pytest -m "not integration"
```

### Integration Tests

Require running services or databases:

```bash
pytest -m integration
```

### Coverage Goals

- Health endpoints: 100%
- Common utilities: 90%+
- Business logic: 80%+

Run coverage report:

```bash
pytest --cov=backend --cov-report=html
open htmlcov/index.html
```

## 🗂️ Research & Legacy Code

### `research/notebooks/`

Jupyter notebooks for experimentation, analysis, evaluation:

- `nlp/` - NLP model experiments
- `vision/` - Computer vision experiments

### `research/experiments/`

FastAPI-based experimental features (framework.py, integration.py)

### `research/legacy_src/`

Archived `backend/api/src/` code for reference:

- `analytics/` - Dashboard analytics (advanced feature)
- `auth/` - OAuth providers, RBAC, 2FA, session management
- `communication/` - Realtime chat, notification system
- `data_management/` - Backup/recovery, retention policies
- `matching/` - Advanced matching engine
- `performance/` - Database optimization, query caching

**Note**: Active code from `src/models/soft_delete.py` was migrated to `backend/common/models/`.

## 🔄 Migration Guide

### For Developers

If you have local branches referencing old paths:

1. **Update imports from `src.*`**:

   ```python
   # Old
   from src.models.soft_delete import SoftDeleteMixin

   # New
   from backend.common.models.soft_delete import SoftDeleteMixin
   ```

2. **Update notebook paths**:

   - Old: `backend/nlp/notebooks/`
   - New: `research/notebooks/nlp/`

3. **Rebuild Docker images**:
   ```bash
   docker compose -f deployment/docker-compose-local.yml build --no-cache
   ```

### For CI/CD

Update workflows to:

- Use `pyproject.toml` for dependency installation
- Run `pytest` from repo root
- Build shared base image first: `docker build backend/base -t lost-found/python-base:latest`
- Health check endpoints: `/healthz` and `/readyz`

## 📊 Metrics & Monitoring

### Prometheus Integration (Future)

Readiness endpoints can be scraped for metrics:

```yaml
scrape_configs:
  - job_name: "lost-found-api"
    metrics_path: "/readyz"
    static_configs:
      - targets: ["api:8000"]
```

### Kubernetes Probes

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8000
readinessProbe:
  httpGet:
    path: /readyz
    port: 8000
```

## 🤝 Contributing

When adding new backend services:

1. Create service directory under `backend/`
2. Add `.dockerignore`
3. Implement `/healthz` and `/readyz` endpoints
4. Register checks with `backend.common.health.readiness`
5. Add service extras to `pyproject.toml`
6. Write tests in `tests/`
7. Update this README

## 📝 Additional Resources

- [Architecture Documentation](../docs/architecture.md)
- [API Documentation](http://localhost:8000/docs) (when running)
- [Test Documentation](../tests/README.md)
- [Deployment Guide](../deployment/README.md)

---

**Last Updated**: October 4, 2025
**Version**: 2.0.0
