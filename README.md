# Lost & Found Application

A comprehensive Lost & Found application built with Domain-Driven Design (DDD) architecture, featuring advanced matching algorithms, image processing, and natural language processing capabilities.

## 🏗️ Architecture Overview

The application follows Domain-Driven Design principles with the following structure:

```
lost-found/
├── services/           # Backend services
│   ├── api/           # Main API service (FastAPI)
│   ├── nlp/           # NLP service for text processing
│   └── vision/        # Vision service for image processing
├── apps/              # Frontend applications
│   ├── admin/         # Admin panel (Next.js)
│   └── mobile/        # Mobile app (Flutter)
└── infra/             # Infrastructure configuration
    └── compose/       # Docker Compose setup
```

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- Git
- Node.js 18+ (for local development)
- Python 3.11+ (for local development)
- Flutter SDK (for mobile development)

### Deployment

#### Option 1: Automated Deployment (Recommended)

**Linux/macOS:**

```bash
chmod +x deploy.sh
./deploy.sh deploy
```

**Windows:**

```cmd
deploy.bat deploy
```

#### Option 2: Manual Deployment

1. **Clone the repository:**

   ```bash
   git clone <repository-url>
   cd lost-found
   ```

2. **Generate environment files:**

   ```bash
   cp infra/compose/env.development infra/compose/.env
   ```

3. **Build and start services:**

   ```bash
   cd infra/compose
   docker compose up -d --build
   ```

4. **Check service health:**

   ```bash
   docker compose ps
   ```

## 🌐 Service URLs

### Local Access

- **Admin Panel:** <http://localhost:3000>
- **API Service:** <http://localhost:8000>
- **NLP Service:** <http://localhost:8001>
- **Vision Service:** <http://localhost:8002>
- **Nginx Proxy:** <http://localhost:8080>
- **pgAdmin:** <http://localhost:5050>
- **MinIO Console:** <http://localhost:9001>

### Server Access (172.104.40.189)

- **Admin Panel:** <http://172.104.40.189:3000>
- **API Service:** <http://172.104.40.189:8000>
- **Nginx Proxy:** <http://172.104.40.189:8080>

## 🔑 Default Credentials

- **Database:** postgres / postgres
- **pgAdmin:** postgres / postgres
- **MinIO:** minioadmin / minioadmin123
- **Redis:** LF_Redis_2025_Pass!

## 📋 Available Commands

### Deployment Script Commands

```bash
# Full deployment
./deploy.sh deploy

# Start services
./deploy.sh start

# Stop services
./deploy.sh stop

# Restart services
./deploy.sh restart

# Check health
./deploy.sh health

# Show logs
./deploy.sh logs

# Show URLs
./deploy.sh urls

# Cleanup (remove all data)
./deploy.sh cleanup

# Interactive menu
./deploy.sh menu
```

### Docker Compose Commands

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# View logs
docker compose logs -f

# Check service status
docker compose ps

# Restart specific service
docker compose restart api

# Scale services
docker compose up -d --scale api=3
```

## 🏛️ Domain Architecture

### Core Domains

1. **Reports Domain**
   - Lost and found item reports
   - Report creation, updates, and management
   - Status tracking and approval workflow

2. **Matches Domain**
   - Intelligent matching between lost and found items
   - Score calculation and ranking
   - Match confirmation and rejection

3. **Users Domain**
   - User management and authentication
   - Profile management and preferences
   - User statistics and activity tracking

4. **Media Domain**
   - Image upload and storage
   - Media processing and optimization
   - File management and cleanup

5. **Taxonomy Domain**
   - Category management
   - Hierarchical organization
   - Search and filtering support

### Service Architecture

#### API Service (FastAPI)

- **Port:** 8000
- **Framework:** FastAPI with async support
- **Database:** PostgreSQL with PostGIS
- **Cache:** Redis
- **Storage:** MinIO (S3-compatible)
- **Authentication:** JWT tokens
- **Features:**
  - Domain-driven design
  - Comprehensive health checks
  - Rate limiting
  - Metrics collection
  - CORS support

#### NLP Service (FastAPI)

- **Port:** 8001
- **Purpose:** Text processing and similarity matching
- **Features:**
  - Fuzzy text matching
  - Semantic similarity
  - NLTK integration
  - Scikit-learn for ML
  - Redis caching
  - Multiple algorithms (fuzzy, cosine, levenshtein, jaro-winkler)

#### Vision Service (FastAPI)

- **Port:** 8002
- **Purpose:** Image processing and similarity matching
- **Features:**
  - Multiple hash algorithms (phash, dhash, ahash, whash)
  - OpenCV integration
  - Scikit-image for advanced processing
  - Image quality assessment
  - Redis caching
  - Advanced similarity algorithms

#### Admin Panel (Next.js)

- **Port:** 3000
- **Framework:** Next.js 14
- **Features:**
  - Modern React with TypeScript
  - Tailwind CSS for styling
  - Comprehensive admin interface
  - Real-time updates
  - File upload support
  - Responsive design

#### Mobile App (Flutter)

- **Framework:** Flutter
- **Features:**
  - Cross-platform support
  - Offline capabilities
  - Camera integration
  - Location services
  - Push notifications
  - Modern UI/UX

## 🔧 Configuration

### Environment Variables

The application supports multiple environments through environment files:

- `infra/compose/env.development` - Development configuration
- `infra/compose/env.production` - Production configuration

### Key Configuration Options

#### Database

```env
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=lostfound
DB_PORT=5433
```

#### Redis

```env
REDIS_PASSWORD=LF_Redis_2025_Pass!
REDIS_PORT=6379
```

#### MinIO

```env
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin123
MINIO_PORT=9000
```

#### CORS

```env
CORS_ORIGINS=http://localhost:3000,http://localhost:8080,http://172.104.40.189:3000,http://172.104.40.189:8080
```

## 🧪 Testing

### Health Checks

All services include comprehensive health checks:

```bash
# Check API health
curl http://localhost:8000/v1/health

# Check NLP health
curl http://localhost:8001/health

# Check Vision health
curl http://localhost:8002/health

# Check Admin health
curl http://localhost:3000/api/health
```

### API Testing

```bash
# Test report creation
curl -X POST http://localhost:8000/v1/reports \
  -H "Content-Type: application/json" \
  -d '{"title": "Lost iPhone", "description": "Black iPhone 13", "type": "lost"}'

# Test text similarity
curl -X POST http://localhost:8001/similarity \
  -H "Content-Type: application/json" \
  -d '{"text1": "Lost iPhone", "text2": "Found iPhone", "algorithm": "combined"}'

# Test image hashing
curl -X POST http://localhost:8002/hash \
  -F "file=@image.jpg"
```

## 📊 Monitoring

### Metrics

The API service exposes Prometheus-compatible metrics at `/metrics`:

- Request count and latency
- Database connection pool status
- Cache hit/miss ratios
- Service health status

### Logging

All services use structured logging with configurable levels:

```env
LOG_LEVEL=INFO  # DEBUG, INFO, WARNING, ERROR
```

### Health Monitoring

Each service provides detailed health information:

- Database connectivity
- Redis connectivity
- External service dependencies
- Resource usage
- Service-specific metrics

## 🔒 Security

### Authentication

- JWT-based authentication
- Token expiration and refresh
- Role-based access control

### CORS

- Configurable origins
- Support for both local and server access
- Secure headers

### Rate Limiting

- Configurable rate limits
- Per-endpoint limits
- Redis-backed rate limiting

### Data Protection

- Password hashing with bcrypt
- Secure file upload validation
- Input sanitization and validation

## 🚀 Production Deployment

### Prerequisites

- Docker and Docker Compose
- Domain name and SSL certificates
- Production environment variables
- Monitoring and logging setup

### Steps

1. Update environment variables for production
2. Configure SSL certificates
3. Set up monitoring and alerting
4. Configure backup strategies
5. Deploy using production compose file

### Scaling

- Horizontal scaling with multiple API instances
- Load balancing with Nginx
- Database connection pooling
- Redis clustering for high availability

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:

- Create an issue in the repository
- Check the documentation
- Review the health check endpoints
- Check service logs for debugging

## 🔄 Updates

To update the application:

1. Pull the latest changes
2. Rebuild services: `docker compose build`
3. Restart services: `docker compose up -d`
4. Check health: `./deploy.sh health`

---

**Note:** This application is configured to work with both local development and server deployment (172.104.40.189). All services are designed to be accessible from both localhost and the server IP address.
