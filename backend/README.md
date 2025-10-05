# Backend Services

This directory contains all backend microservices for the Lost & Found system.

## Services

### API Service (`api/`)

Main FastAPI application handling:

- User authentication & authorization
- Item management (lost/found items)
- Matching algorithm coordination
- Chat messaging
- Admin operations
- Media upload/download

**Tech Stack**: FastAPI, SQLAlchemy, PostgreSQL + PostGIS, Alembic

### NLP Service (`nlp/`)

Natural Language Processing microservice (optional):

- Multilingual text embeddings
- Named Entity Recognition (NER)
- Language detection
- Translation services
- Text similarity computation

**Tech Stack**: FastAPI, spaCy, sentence-transformers, PyTorch

### Vision Service (`vision/`)

Computer Vision microservice (optional):

- Perceptual image hashing
- Image similarity computation
- Optional CLIP embeddings
- Image preprocessing

**Tech Stack**: FastAPI, PIL, imagehash, OpenCV

### Worker Service (`worker/`)

Background task processor:

- Thumbnail generation
- Batch matching computations
- Email/SMS notifications
- Data cleanup jobs

**Tech Stack**: Celery, Redis, boto3

### Common (`common/`)

Shared utilities and health check endpoints used across services.

## Setup

### Install Dependencies

Each service has its own `requirements.txt`:

```bash
# API service
cd api && pip install -r requirements.txt

# NLP service
cd nlp && pip install -r requirements.txt

# Vision service
cd vision && pip install -r requirements.txt

# Worker service
cd worker && pip install -r requirements.txt
```

### Database Setup

```bash
cd api
alembic upgrade head
```

### Running Services

```bash
# API (port 8000)
cd api
uvicorn app.main:app --reload --port 8000

# NLP (port 8090)
cd nlp
python server/main.py

# Vision (port 8091)
cd vision
python server/main.py

# Worker
cd worker
celery -A worker.jobs worker --loglevel=info
```

## Configuration

Services can be configured via environment variables. See individual service `.env.example` files.

### Feature Flags

- `NLP_ON=true/false`: Enable/disable NLP service integration
- `CV_ON=true/false`: Enable/disable vision service integration

When disabled, the system uses baseline matching only (geo-temporal + attributes).

## API Documentation

Once the API service is running, visit:

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Testing

```bash
cd api
pytest
```
