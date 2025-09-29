# Multi-stage build for Vision service
FROM python:3.11-slim as base

# Install system dependencies for computer vision
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    software-properties-common \
    git \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libglib2.0-0 \
    libgtk-3-0 \
    libgl1-mesa-glx \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Pre-download CLIP model (optional, for faster startup)
RUN python -c "import clip; clip.load('ViT-B/32')" || echo "CLIP model download failed, will download on first use"

# Copy application code
COPY . .

# Create non-root user
RUN useradd --create-home --shell /bin/bash vision
RUN chown -R vision:vision /app
USER vision

# Expose port
EXPOSE 8091

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8091/health || exit 1

# Start command
CMD ["python", "-m", "uvicorn", "server.enhanced_main:app", "--host", "0.0.0.0", "--port", "8091"]
