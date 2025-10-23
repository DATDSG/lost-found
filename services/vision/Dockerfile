# ================================================================
# Vision Service Dockerfile - Enhanced for Domain-Driven Architecture
# ================================================================
# Optimized for better image processing and matching in DDD context
# Includes OpenCV, scikit-image, advanced hashing, and Redis integration
# ================================================================

FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libjpeg62-turbo \
    zlib1g \
    libgl1 \
    libglib2.0-0 \
    libgomp1 \
    libgthread-2.0-0 \
    libgtk-3-0 \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libv4l-dev \
    libxvidcore-dev \
    libx264-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libopenblas-dev \
    python3-dev \
    curl \
    gcc \
    g++ \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . /app

# Create necessary directories
RUN mkdir -p /app/cache /app/logs /app/uploads

# Environment variables for DDD architecture
ENV PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app \
    LOG_LEVEL=INFO \
    ENVIRONMENT=production \
    # Vision-specific settings
    SIMILARITY_THRESHOLD=0.8 \
    HASH_THRESHOLD_SIMILAR=10 \
    HASH_THRESHOLD_MATCH=5 \
    MAX_MATCHES=20 \
    CACHE_TTL=3600 \
    # Redis settings
    REDIS_MAX_CONNECTIONS=10 \
    # Performance settings
    WORKER_CONCURRENCY=4 \
    MAX_IMAGE_SIZE=10485760 \
    MAX_IMAGE_DIMENSION=4096 \
    # OpenCV settings
    OPENCV_IO_ENABLE_OPENEXR=1 \
    OPENCV_IO_ENABLE_JASPER=1

# Expose port
EXPOSE 8002

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
    CMD curl -f http://localhost:8002/health || exit 1

# Run the application with optimized settings
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8002", "--workers", "2", "--access-log"]