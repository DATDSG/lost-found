# Multi-stage build for NLP service
FROM python:3.11-slim as base

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    software-properties-common \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Download spaCy models
RUN python -m spacy download en_core_web_sm
RUN python -m spacy download xx_ent_wiki_sm || echo "Multilingual model not available, using English fallback"

# Copy application code
COPY . .

# Create non-root user
RUN useradd --create-home --shell /bin/bash nlp
RUN chown -R nlp:nlp /app
USER nlp

# Expose port
EXPOSE 8090

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8090/health || exit 1

# Start command
CMD ["python", "-m", "uvicorn", "server.main:app", "--host", "0.0.0.0", "--port", "8090"]
