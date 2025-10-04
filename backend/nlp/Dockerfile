# NLP service
FROM python:3.11-slim AS nlp-base

LABEL org.opencontainers.image.description="Lost & Found NLP microservice" \
    org.opencontainers.image.component="nlp"

# Prevent Python from writing pyc files and buffering stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Optional build arg to prefer CPU-only torch wheels
ARG TORCH_DEVICE=cpu
ENV TORCH_DEVICE=${TORCH_DEVICE}

# Install Python dependencies (replace heavy CUDA wheels with CPU-only when TORCH_DEVICE=cpu)
RUN pip install --no-cache-dir --upgrade pip && \
    if [ "$TORCH_DEVICE" = "cpu" ]; then \
    sed -i "s/^torch==2.1.1.*/torch==2.1.1+cpu/" requirements.txt || true; \
    pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu -r requirements.txt; \
    else \
    pip install --no-cache-dir -r requirements.txt; \
    fi

# Download spaCy models (explicit pin to avoid 404 from auto resolver)
# If these wheels ever 404, runtime code will attempt a lazy download.
ARG SPACY_EN_MODEL_VERSION=3.7.1
ARG SPACY_XX_MODEL_VERSION=3.7.0
ENV SPACY_EN_MODEL_VERSION=${SPACY_EN_MODEL_VERSION} \
    SPACY_XX_MODEL_VERSION=${SPACY_XX_MODEL_VERSION}
RUN set -eux; \
    for MODEL VER in en_core_web_sm ${SPACY_EN_MODEL_VERSION} xx_ent_wiki_sm ${SPACY_XX_MODEL_VERSION}; do :; done; \
    pip install --no-cache-dir \
    "https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-${SPACY_EN_MODEL_VERSION}/en_core_web_sm-${SPACY_EN_MODEL_VERSION}-py3-none-any.whl" \
    || echo "Could not preinstall en_core_web_sm ${SPACY_EN_MODEL_VERSION}"; \
    pip install --no-cache-dir \
    "https://github.com/explosion/spacy-models/releases/download/xx_ent_wiki_sm-${SPACY_XX_MODEL_VERSION}/xx_ent_wiki_sm-${SPACY_XX_MODEL_VERSION}-py3-none-any.whl" \
    || echo "Could not preinstall xx_ent_wiki_sm ${SPACY_XX_MODEL_VERSION} (optional)"

# Copy application code
COPY . .

# User already created in base

# Expose port
EXPOSE 8090

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8090/health || exit 1

# Start command
CMD ["python", "-m", "uvicorn", "server.main:app", "--host", "0.0.0.0", "--port", "8090"]
