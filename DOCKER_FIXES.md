# Docker Setup - Fixed Issues ✅

## Issues Fixed

### 1. Docker Context Path Error

**Problem**: `path "C:\\Users\\td123\\OneDrive\\Documents\\GitHub\\frontend\\web-admin" not found`

**Cause**: Docker build contexts were incorrectly pointing to `..` (parent directory) instead of `.` (current directory).

**Solution**: Updated all build contexts in `docker-compose.yml`:

- Changed `context: ..` to `context: .` for backend services
- Changed `context: ../frontend/web-admin` to `context: ./frontend/web-admin`

### 2. Dockerfile COPY Paths

**Problem**: Dockerfiles couldn't find `requirements.txt` and other files

**Cause**: COPY commands assumed files were in the build context root, but with the new context, files are in subdirectories.

**Solution**: Updated all Dockerfiles to use correct paths:

- Changed `COPY requirements.txt .` to `COPY backend/[service]/requirements.txt .`
- Updated all backend service Dockerfiles (api, nlp, vision, worker)

### 3. NPM CI Error in Web Admin

**Problem**: `npm ci` failed because `package-lock.json` doesn't exist

**Solution**: Changed Dockerfile to use `npm install` instead of `npm ci`

### 4. Obsolete libgl1-mesa-glx Package

**Problem**: Vision service couldn't install `libgl1-mesa-glx` package

**Solution**: Updated to use `libgl1` package (modern Debian package name)

### 5. Docker Compose Version Warning

**Problem**: Warning about obsolete `version` attribute

**Solution**: Removed `version: "3.8"` from docker-compose.yml

## Current Status

Docker containers are building. This process takes 5-10 minutes on first run because it needs to:

- Download base images (Python, Node)
- Install system packages
- Install Python packages (including PyTorch, transformers for NLP)
- Install Node.js packages
- Download spaCy language models

## Check Build Progress

```bash
# Check build status
docker-compose ps

# Watch logs
docker-compose logs -f

# Check specific service
docker-compose logs -f api
```

## After Build Completes

1. **Initialize MinIO bucket**:

   - Open http://localhost:9001
   - Login: minioadmin / minioadmin
   - Create bucket: `media`
   - Set to public read

2. **Run database migrations**:

   ```bash
   docker-compose exec api alembic upgrade head
   ```

3. **Access applications**:

   - API Docs: http://localhost:8000/docs
   - Admin Panel: http://localhost:3000
   - MinIO Console: http://localhost:9001

4. **Login**:
   - Email: admin@example.com
   - Password: admin123

## Files Modified

✅ `docker-compose.yml` - Fixed all build contexts and removed version
✅ `backend/api/Dockerfile` - Fixed COPY paths
✅ `backend/nlp/Dockerfile` - Fixed COPY paths
✅ `backend/vision/Dockerfile` - Fixed COPY paths and package name
✅ `backend/worker/Dockerfile` - Fixed COPY paths
✅ `frontend/web-admin/Dockerfile` - Changed npm ci to npm install

## Next Time

To rebuild and start services:

```bash
docker-compose up -d --build
```

To stop services:

```bash
docker-compose down
```

To view logs:

```bash
docker-compose logs -f [service-name]
```
