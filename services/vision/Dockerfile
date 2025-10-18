# ================================================================
# Vision Service Dockerfile - Lightweight (CPU Only)
# ================================================================
# Image size: ~800MB-1GB (vs 12-15GB with GPU)
# Basic image processing without heavy ML models
# For GPU support with ML models, use Dockerfile.gpu
# Multi-stage build for optimal image size
# ================================================================

# ================================================================
# Stage 1: Builder
# ================================================================
FROM python:3.11-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    libjpeg-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy requirements
COPY requirements.txt .

# Set pip timeout and retry settings
ENV PIP_DEFAULT_TIMEOUT=300

# Install Python dependencies with increased timeout and retries
RUN pip install --no-cache-dir --upgrade pip wheel && \
    pip install --no-cache-dir --retries 5 --user -r requirements.txt

# ================================================================
# Stage 2: Runtime (Minimal)
# ================================================================
FROM python:3.11-slim

WORKDIR /app

# Install only runtime dependencies (minimal)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libjpeg62-turbo \
    zlib1g \
    libgl1 \
    libglib2.0-0 \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy Python packages from builder
COPY --from=builder /root/.local /root/.local

# Copy application files
COPY . /app

# Environment variables
ENV PATH=/root/.local/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    LOG_LEVEL=INFO \
    USE_GPU=false \
    ENABLE_METRICS=true \
    ENABLE_RATE_LIMIT=true \
    ENABLE_OBJECT_DETECTION=false \
    ENABLE_OCR=false \
    ENABLE_CLIP=false \
    ENABLE_NSFW_DETECTION=false \
    REDIS_URL=redis://redis:6379

# Expose port
EXPOSE 8002

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8002/health || exit 1

# Run application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8002", "--workers", "1"]
