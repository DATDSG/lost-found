# ================================================================
# NLP Service Dockerfile - CPU Optimized (Lightweight)
# ================================================================
# Image size: ~2-3GB (vs 8-10GB with GPU)
# For GPU support, use Dockerfile.gpu
# Multi-stage build for better caching and optimization
# ================================================================

# ================================================================
# Stage 1: Builder
# ================================================================
FROM python:3.11-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy requirements first for better caching
COPY requirements.txt .

# Set pip timeout and retry settings
ENV PIP_DEFAULT_TIMEOUT=300

# Install dependencies in optimized order
# 1. Install pip and wheel for faster builds
RUN pip install --no-cache-dir --upgrade pip wheel

# 2. Install lightweight dependencies first
RUN pip install --no-cache-dir --retries 5 --user \
    fastapi==0.109.0 \
    uvicorn[standard]==0.27.0 \
    pydantic==2.5.3 \
    httpx==0.26.0 \
    python-multipart==0.0.6 \
    redis[hiredis]==5.0.1 \
    prometheus-client==0.19.0 \
    slowapi==0.1.9 \
    arq==0.25.0 \
    numpy==1.26.3

# 3. Install PyTorch CPU-only version (much smaller than GPU version)
# CPU version: ~200MB | GPU version with CUDA: ~2GB+
RUN pip install --no-cache-dir --retries 5 --user \
    torch==2.1.0 \
    --index-url https://download.pytorch.org/whl/cpu

# 4. Install transformers and sentence-transformers
RUN pip install --no-cache-dir --retries 5 --user \
    transformers==4.37.2 \
    sentence-transformers==2.3.1

# ================================================================
# Stage 2: Runtime
# ================================================================
FROM python:3.11-slim

WORKDIR /app

# Install only runtime dependencies (minimal)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy Python packages from builder
COPY --from=builder /root/.local /root/.local

# Copy application code
COPY . /app

# Pre-download default model during build (optional)
# This increases build time but speeds up first request
# Uncomment if you want to bake models into the image
# RUN python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('intfloat/e5-small-v2')"

# Environment variables
ENV PATH=/root/.local/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    LOG_LEVEL=INFO \
    USE_GPU=false

# Expose port
EXPOSE 8001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8001/health || exit 1

# Run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001", "--workers", "1"]
