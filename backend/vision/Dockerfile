FROM python:3.11-slim

WORKDIR /app

# Install system dependencies for image processing
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgl1 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install
COPY backend/vision/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy common shared module
COPY backend/common /app/backend/common

# Copy application code
COPY backend/vision /app/backend/vision

# Set Python path
ENV PYTHONPATH=/app

WORKDIR /app/backend/vision

# Start Vision service
CMD ["python", "server/main.py"]
