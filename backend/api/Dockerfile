FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    postgresql-client \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY backend/api/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy common shared module
COPY backend/common /app/backend/common

# Copy application code
COPY backend/api /app/backend/api

# Set Python path
ENV PYTHONPATH=/app

WORKDIR /app/backend/api

# Run migrations and start server
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
