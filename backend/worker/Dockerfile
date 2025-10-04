FROM python:3.11-slim AS worker-base

LABEL org.opencontainers.image.description="Lost & Found background worker service" \
    org.opencontainers.image.component="worker"

# Prevent Python from writing pyc files and buffering stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

# Set working directory
WORKDIR /app

# Install Python dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . .

# Base user already set

# Run worker
CMD ["python", "-m", "worker.jobs"]