# ================================================================
# NLP Service Dockerfile - Enhanced for Domain-Driven Architecture
# ================================================================
# Optimized for better text processing and matching in DDD context
# Includes fuzzy matching, NLTK, scikit-learn, and Redis integration
# ================================================================

FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
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

# Download NLTK data during build
RUN python -c "import nltk; nltk.download('punkt'); nltk.download('stopwords'); nltk.download('wordnet')"

# Copy application code
COPY . /app

# Create necessary directories
RUN mkdir -p /app/cache /app/logs

# Environment variables for DDD architecture
ENV PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app \
    LOG_LEVEL=INFO \
    ENVIRONMENT=production \
    # NLP-specific settings
    SIMILARITY_THRESHOLD=0.7 \
    FUZZY_MATCH_THRESHOLD=80 \
    MAX_MATCHES=10 \
    CACHE_TTL=3600 \
    # Redis settings
    REDIS_MAX_CONNECTIONS=10 \
    # Performance settings
    WORKER_CONCURRENCY=4 \
    MAX_TEXT_LENGTH=10000

# Expose port
EXPOSE 8001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
    CMD curl -f http://localhost:8001/health || exit 1

# Run the application with optimized settings
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001", "--workers", "2", "--access-log"]