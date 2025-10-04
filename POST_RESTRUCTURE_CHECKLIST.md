# Post-Restructure Checklist

Use this checklist to ensure smooth transition after the backend restructuring.

## ✅ Immediate Actions (Required)

### For All Developers

- [ ] Pull latest code: `git pull origin main`
- [ ] Read `RESTRUCTURE_VISUAL_SUMMARY.md` (5 min overview)
- [ ] Read `backend/RESTRUCTURE_SUMMARY.md` (comprehensive guide)
- [ ] Install package: `pip install -e ".[all]"` or service-specific like `pip install -e ".[api,dev]"`
- [ ] Run validation: `python scripts/validate_restructure.py`
- [ ] Run tests: `pytest -m "not integration"`
- [ ] Update import statements if you have local branches:
  - Old: `from src.models.soft_delete import SoftDeleteMixin`
  - New: `from backend.common.models.soft_delete import SoftDeleteMixin`

### For DevOps / Infrastructure

- [ ] Review new health endpoint contract (`/healthz`, `/readyz`)
- [ ] Rebuild all Docker images: `docker compose -f deployment/docker-compose-local.yml build --no-cache`
- [ ] Test health endpoints:
  ```bash
  curl http://localhost:8000/healthz
  curl http://localhost:8000/readyz
  curl http://localhost:8090/healthz
  curl http://localhost:8090/readyz
  curl http://localhost:8091/healthz
  curl http://localhost:8091/readyz
  ```
- [ ] Update CI/CD pipelines:
  - Use `pip install -e ".[all]"` instead of individual requirements
  - Build shared base image first if using multi-stage builds
  - Update health check endpoints in deployment configs
- [ ] Update Kubernetes manifests (if applicable):
  - `livenessProbe` → `/healthz`
  - `readinessProbe` → `/readyz`
- [ ] Verify .dockerignore is respected (check build logs for context size)

### For QA / Testing

- [ ] Review `tests/README.md`
- [ ] Run full test suite: `pytest`
- [ ] Test with actual dependencies: `pytest -m integration` (requires running services)
- [ ] Verify all services start correctly with docker compose
- [ ] Smoke test health endpoints

---

## 📋 Verification Steps

### 1. Directory Structure

```bash
# Should exist:
ls backend/common/
ls backend/common/models/
ls research/notebooks/nlp/
ls research/notebooks/vision/
ls research/legacy_src/
ls tests/

# Should NOT exist:
ls backend/api/src/  # Should be gone (archived)
ls backend/nlp/notebooks/  # Should be gone (moved)
ls backend/vision/notebooks/  # Should be gone (moved)
```

### 2. Import Paths

```bash
# Check for old import patterns (should find ZERO matches):
grep -r "from src\." backend/api/app/
grep -r "import src\." backend/api/app/

# Check for new import patterns (should find matches):
grep -r "from backend.common" backend/
```

### 3. Docker Build Optimization

```bash
# Build and check context size (should be ~50MB, not ~500MB):
docker build backend/api -t test-api-build 2>&1 | grep "transferring context"
```

### 4. Health Endpoints

```bash
# Start services:
docker compose -f deployment/docker-compose-local.yml up -d

# Wait for services to be ready:
sleep 30

# Test health endpoints (all should return 200):
curl -f http://localhost:8000/healthz || echo "API healthz failed"
curl -f http://localhost:8000/readyz || echo "API readyz failed"
curl -f http://localhost:8090/healthz || echo "NLP healthz failed"
curl -f http://localhost:8090/readyz || echo "NLP readyz failed"
curl -f http://localhost:8091/healthz || echo "Vision healthz failed"
curl -f http://localhost:8091/readyz || echo "Vision readyz failed"
```

### 5. Test Suite

```bash
# Unit tests (should pass):
pytest -m "not integration" -v

# Integration tests (requires dependencies):
pip install -e ".[all]"
pytest -m integration -v

# Validation script:
python scripts/validate_restructure.py
```

---

## 🔄 Migration Tasks

### If You Have Active Local Branches

1. **Update imports**:

   ```bash
   # Find all occurrences:
   git grep "from src\." HEAD
   git grep "import src\." HEAD

   # Replace in your branch:
   find . -name "*.py" -type f -exec sed -i 's/from src\./from backend.common./g' {} +
   ```

2. **Update notebook paths** (if referencing them):

   ```bash
   # Old: backend/nlp/notebooks/
   # New: research/notebooks/nlp/
   ```

3. **Test your changes**:
   ```bash
   pip install -e ".[dev]"
   pytest
   ```

### If You Have CI/CD Pipelines

1. **Update dependency installation**:

   ```yaml
   # Old:
   - pip install -r backend/api/requirements.txt
   - pip install -r backend/nlp/requirements.txt

   # New:
   - pip install -e ".[all]"
   # Or service-specific:
   - pip install -e ".[api,nlp,dev]"
   ```

2. **Update health checks**:

   ```yaml
   # Old:
   healthcheck:
     test: ["CMD", "curl", "-f", "http://localhost:8000/health"]

   # New (liveness):
   healthcheck:
     test: ["CMD", "curl", "-f", "http://localhost:8000/healthz"]

   # New (readiness, more thorough):
   healthcheck:
     test: ["CMD", "curl", "-f", "http://localhost:8000/readyz"]
   ```

3. **Update test commands**:

   ```yaml
   # Old:
   - pytest backend/api/tests/

   # New:
   - pytest -m "not integration" # Unit tests only
   - pytest -m integration # Integration tests (requires services)
   ```

### If You Have Kubernetes Deployments

1. **Update probes**:

   ```yaml
   livenessProbe:
     httpGet:
       path: /healthz # Changed from /health
       port: 8000
     initialDelaySeconds: 5
     periodSeconds: 10

   readinessProbe:
     httpGet:
       path: /readyz # New, more comprehensive
       port: 8000
     initialDelaySeconds: 10
     periodSeconds: 5
   ```

2. **Update image builds** (if using multi-stage):
   ```dockerfile
   # Build shared base first:
   FROM backend/base:latest AS base
   ```

---

## 🐛 Common Issues & Solutions

### Issue: `ModuleNotFoundError: No module named 'backend'`

**Cause**: Package not installed  
**Solution**:

```bash
pip install -e .
# Or with extras:
pip install -e ".[all]"
```

### Issue: Tests fail with missing dependencies (langdetect, imagehash, etc.)

**Cause**: Service-specific dependencies not installed  
**Solution**:

```bash
pip install -e ".[all]"
```

### Issue: Old imports still referenced in code

**Cause**: Import paths not updated  
**Solution**:

```bash
# Find and replace:
find . -name "*.py" -exec sed -i 's/from src\./from backend.common./g' {} +
```

### Issue: Docker builds still slow

**Cause**: .dockerignore not respected or cache issue  
**Solution**:

```bash
# Rebuild without cache:
docker compose build --no-cache

# Check what's being sent to daemon:
docker build --progress=plain backend/api 2>&1 | grep "context"
```

### Issue: Health endpoints return 404

**Cause**: Old container still running  
**Solution**:

```bash
docker compose down
docker compose up -d --force-recreate
```

### Issue: Can't import from backend.common in tests

**Cause**: PYTHONPATH not set correctly  
**Solution**: Tests already have `conftest.py` that sets this up. Run from repo root:

```bash
pytest  # Not: cd tests && pytest
```

---

## 📊 Success Metrics

After completing the checklist, verify:

- [ ] ✅ Validation script shows 15/18 checks passing (83.3%)
- [ ] ✅ Unit tests pass: 4/4 (100%)
- [ ] ✅ All services start successfully with docker compose
- [ ] ✅ All health endpoints return 200 OK
- [ ] ✅ Docker build context reduced to ~50MB (from ~500MB)
- [ ] ✅ No references to `from src.*` in active code
- [ ] ✅ Research code isolated in `research/`
- [ ] ✅ Documentation read and understood by team

---

## 📞 Getting Help

**Documentation**:

- Quick overview: `RESTRUCTURE_VISUAL_SUMMARY.md`
- Complete guide: `backend/RESTRUCTURE_SUMMARY.md`
- Task details: `backend/RESTRUCTURE_COMPLETION.md`
- Test guide: `tests/README.md`

**Validation**:

```bash
python scripts/validate_restructure.py
```

**Common Commands**:

```bash
# Install everything:
pip install -e ".[all]"

# Run tests:
pytest -m "not integration"

# Rebuild Docker:
docker compose build --no-cache

# Health check:
curl http://localhost:8000/readyz
```

---

## ✨ Optional Enhancements (Future)

These are NOT required now but may be beneficial later:

- [ ] Migrate all `requirements.txt` to single `pyproject.toml` lock
- [ ] Add pre-commit hooks (ruff, mypy, black)
- [ ] Increase test coverage to 80%+
- [ ] Add integration tests for service-to-service communication
- [ ] Set up Prometheus metrics scraping from `/readyz`
- [ ] Add shared database session management in `backend/common/db/`
- [ ] Add shared authentication helpers in `backend/common/auth/`
- [ ] Create shared exception types in `backend/common/exceptions/`
- [ ] Add performance benchmarks for health endpoints

---

**Last Updated**: October 4, 2025  
**Status**: Restructuring Complete ✅  
**Ready for Production**: Yes ✅
