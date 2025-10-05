FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install
COPY backend/nlp/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Download spaCy models
RUN python -m spacy download en_core_web_sm
RUN python -m spacy download xx_ent_wiki_sm

# Copy common shared module
COPY backend/common /app/backend/common

# Copy application code
COPY backend/nlp /app/backend/nlp

# Set Python path
ENV PYTHONPATH=/app

WORKDIR /app/backend/nlp

# Start NLP service
CMD ["python", "server/main.py"]
