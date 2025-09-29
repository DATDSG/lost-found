# Backend Services

This directory contains all backend microservices for the Lost & Found system.

## Services

### API Service (`/api`)

Main API gateway and business logic service built with FastAPI.

**Features:**

- RESTful API endpoints
- Authentication and authorization
- Item and user management
- Match processing
- Real-time notifications

**Technology Stack:**

- Python 3.11+
- FastAPI
- SQLAlchemy
- PostgreSQL + PostGIS
- Redis

### NLP Service (`/nlp`)

Natural language processing service for multilingual text analysis.

**Features:**

- Text embedding generation
- Named entity recognition
- Language detection
- Semantic similarity matching

**Technology Stack:**

- Python 3.11+
- Transformers
- spaCy
- scikit-learn

### Vision Service (`/vision`)

Computer vision service for image processing and analysis.

**Features:**

- Image hashing and fingerprinting
- Visual similarity matching
- Feature extraction
- Object detection

**Technology Stack:**

- Python 3.11+
- OpenCV
- PIL/Pillow
- NumPy

### Worker Service (`/worker`)

Background task processing service for async operations.

**Features:**

- Asynchronous job processing
- Email notifications
- Data cleanup tasks
- Scheduled operations

**Technology Stack:**

- Python 3.11+
- Celery
- Redis
- Background tasks

## Getting Started

1. **Environment Setup**

   ```bash
   cd backend/api
   python -m venv venv
   source venv/bin/activate  # or venv\Scripts\activate on Windows
   pip install -r requirements.txt
   ```

2. **Database Setup**

   ```bash
   # Create database and run migrations
   alembic upgrade head
   ```

3. **Start Services**

   ```bash
   # API Service
   uvicorn app.main:app --reload --port 8000

   # NLP Service
   cd ../nlp
   python server/main.py

   # Vision Service
   cd ../vision
   python server/main.py

   # Worker Service
   cd ../worker
   celery -A worker.worker worker --loglevel=info
   ```

## Development

- All services follow the same project structure
- Use environment variables for configuration
- Include proper logging and error handling
- Write unit tests for core functionality
- Follow Python coding standards (PEP 8)

## API Documentation

Once the API service is running, visit:

- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`
