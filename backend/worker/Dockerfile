FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install
COPY backend/worker/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy common shared module
COPY backend/common /app/backend/common

# Copy application code
COPY backend/worker /app/backend/worker

# Set Python path
ENV PYTHONPATH=/app

WORKDIR /app/backend/worker

# Start Celery worker
CMD ["celery", "-A", "worker.jobs", "worker", "--loglevel=info"]
