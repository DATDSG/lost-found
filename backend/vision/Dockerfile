FROM python:3.11-slim

LABEL org.opencontainers.image.description="Lost & Found Vision microservice" \
    org.opencontainers.image.component="vision" \
    org.opencontainers.image.authors="team@lostfound.local"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

# Minimal native libs required by opencv-python-headless
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    libgl1 libglib2.0-0 libsm6 libxext6 libxrender1; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install dependencies first for caching
COPY requirements.txt ./
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Optional heavy ML stack (build arg to pre-install)
ARG INSTALL_CLIP=false
RUN if [ "$INSTALL_CLIP" = "true" ]; then \
    pip install --no-cache-dir torch torchvision --index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir git+https://github.com/openai/CLIP.git@main; \
    fi || echo "Skipping CLIP installation"

COPY . .

# Create non-root user
RUN useradd -m appuser && chown -R appuser /app
USER appuser

EXPOSE 8091

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python - <<'PY' || exit 1\
    import urllib.request, json, sys;\
    try:\
    with urllib.request.urlopen('http://127.0.0.1:8091/healthz', timeout=3) as r:\
    sys.exit(0 if r.status == 200 else 1)\
    except Exception:\
    sys.exit(1)\
    PY

CMD ["python", "-m", "uvicorn", "server.main:app", "--host", "0.0.0.0", "--port", "8091"]
