# ================================================================
# API Service Dockerfile - Optimized
# ================================================================
# Multi-stage build for better caching and smaller final image
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
    postgresql-client \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy requirements first for better caching
COPY requirements.txt .

# Set pip timeout and retry settings
ENV PIP_DEFAULT_TIMEOUT=300

# Install Python dependencies with increased timeout and retries
RUN pip install --no-cache-dir --upgrade pip wheel && \
    pip install --no-cache-dir --retries 5 --user -r requirements.txt

# ================================================================
# Stage 2: Runtime
# ================================================================
FROM python:3.11-slim

WORKDIR /app

# Install only runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy Python packages from builder
COPY --from=builder /root/.local /root/.local

# Copy application code
COPY . /app

# Environment variables
ENV PATH=/root/.local/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    LOG_LEVEL=INFO

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run FastAPI with uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
