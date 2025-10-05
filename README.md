# Lost & Found System

A trilingual (Sinhala, Tamil, English) Lost & Found platform with AI-powered matching capabilities, built with modern microservices architecture.

## 🌟 Features

- **Trilingual Support**: Full support for Sinhala, Tamil, and English
- **AI-Powered Matching**: Optional NLP and Computer Vision services for enhanced matching
- **Geospatial Matching**: Location-based item matching with privacy-preserving fuzzing
- **Real-time Chat**: Secure, masked communication between users
- **Mobile & Web**: Flutter mobile app and Next.js admin panel
- **Microservices Architecture**: Scalable, modular design
- **Privacy-First**: Coordinate fuzzing, masked chat, and comprehensive audit logging

## 🏗️ Architecture

The system consists of multiple services:

- **API Service** (FastAPI): Core backend API with PostgreSQL + PostGIS
- **NLP Service** (FastAPI): Text embedding and language processing (optional)
- **Vision Service** (FastAPI): Image similarity and perceptual hashing (optional)
- **Worker Service** (Celery): Background task processing
- **Web Admin** (Next.js): Administrative dashboard
- **Mobile App** (Flutter): User-facing mobile application

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose (recommended)
- OR Python 3.11+, Node.js 18+, Flutter 3.9+
- PostgreSQL 15+ with PostGIS extension
- Redis 7+
- MinIO or AWS S3

### Using Docker (Recommended)

1. **Clone the repository**

   ```bash
   git clone https://github.com/DATDSG/lost-found.git
   cd lost-found
   ```

2. **Configure environment**

   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Start services**

   ```bash
   docker-compose up -d
   ```

4. **Access the application**
   - API: http://localhost:8000
   - API Docs: http://localhost:8000/docs
   - Admin Panel: http://localhost:3000
   - MinIO Console: http://localhost:9001

### Manual Setup

1. **Install dependencies**

   ```bash
   # Install root dependencies
   npm install

   # Install API dependencies
   cd backend/api
   pip install -r requirements.txt

   # Install web admin dependencies
   cd ../../frontend/web-admin
   npm install

   # Install mobile dependencies
   cd ../mobile
   flutter pub get
   ```

2. **Setup database**

   ```bash
   # Create PostgreSQL database with PostGIS
   createdb lostfound
   psql -d lostfound -c "CREATE EXTENSION postgis;"

   # Run migrations
   cd backend/api
   alembic upgrade head
   ```

3. **Start services**

   ```bash
   # Terminal 1: API
   cd backend/api
   uvicorn app.main:app --reload --port 8000

   # Terminal 2: NLP (optional)
   cd backend/nlp
   python server/main.py

   # Terminal 3: Vision (optional)
   cd backend/vision
   python server/main.py

   # Terminal 4: Worker
   cd backend/worker
   celery -A worker.jobs worker --loglevel=info

   # Terminal 5: Web Admin
   cd frontend/web-admin
   npm run dev

   # Terminal 6: Mobile
   cd frontend/mobile
   flutter run
   ```

## 📁 Project Structure

```bash
lost-found/
├── backend/
│   ├── api/          # Main FastAPI application
│   ├── nlp/          # NLP microservice
│   ├── vision/       # Computer vision microservice
│   ├── worker/       # Celery background workers
│   └── common/       # Shared utilities
├── frontend/
│   ├── web-admin/    # Next.js admin panel
│   └── mobile/       # Flutter mobile app
├── shared/
│   ├── config/       # Shared configuration
│   └── types/        # TypeScript type definitions
├── research/         # Experimental features
├── tests/            # Test suites
├── tools/            # Utility scripts
└── docker-compose.yml
```

## 🔧 Configuration

### Environment Variables

Key configuration options in `.env`:

- `ENV`: Environment (development/production)
- `DATABASE_URL`: PostgreSQL connection string
- `JWT_SECRET`: Secret key for JWT tokens (MUST CHANGE IN PRODUCTION)
- `NLP_ON`: Enable/disable NLP features
- `CV_ON`: Enable/disable computer vision features
- `ADMIN_EMAIL` / `ADMIN_PASSWORD`: Bootstrap admin credentials

See `.env.example` for complete list.

## 🧪 Testing

```bash
# Run all tests
npm test

# API tests
cd backend/api
pytest

# Web admin tests
cd frontend/web-admin
npm test

# Mobile tests
cd frontend/mobile
flutter test
```

## 📦 Building for Production

### Docker Build

```bash
docker-compose -f docker-compose.yml build
docker-compose -f docker-compose.yml up -d
```

### Manual Build

```bash
# Build web admin
cd frontend/web-admin
npm run build

# Build mobile app
cd ../mobile
flutter build apk  # Android
flutter build ios  # iOS
```

## �️ Database Migration Strategy

We use Alembic for schema versioning. The migration chain intentionally separates concerns:

1. `20250925_0001_init` – Core tables (users, items, media, matches, chat, etc.)
2. `20250928_0002_admin_enhancements` – Moderation (flags, moderation_logs) + item category enrichment
3. `20250928_0003_trilingual_architecture` – Language + geospatial expansion + claims + audit logs
4. `add_soft_delete_001` – Soft delete columns to support logical retention
5. `performance_opt_001` – Non‑blocking performance & search indexes (text, trigram, geospatial, compound)

Design principles:

- **Forward-only friendly**: Most migrations add columns with defaults or nullable → minimized locks.
- **PostGIS first**: Spatial extension enabled early so later migrations can assume availability.
- **Idempotent indexing**: All performance indexes use `IF NOT EXISTS` to allow safe re-runs.
- **Volatile predicates avoided**: Time-window partial indexes that depended on `NOW()` were replaced with neutral composites (see `idx_items_status_created_at`). Consider materialized views for rolling windows.

### Reset & Reseed

Inside the API container:

```bash
docker-compose exec api python scripts/reset_database.py --seed
```

### Manual Migration Commands

```bash
docker-compose exec api alembic history
docker-compose exec api alembic current
docker-compose exec api alembic upgrade head
docker-compose exec api alembic downgrade -1  # step back one revision
```

## 🧪 Minimal Seed Data

Seed script creates:

- Admin user: `admin@example.com` / `password123`
- Regular user: `user@example.com` / `password123`
- Example lost + found items (for matching workflows)

Run:

```bash
docker-compose exec api python scripts/seed_minimal_data.py
```

## 🚀 API Smoke Checks

After `docker-compose up -d` and migrations:

```bash
curl -s http://localhost:8000/healthz
curl -s http://localhost:8000/readyz
```

Authenticated example (create token first):

```bash
# Login uses email/password (LoginRequest schema)
LOGIN_JSON='{"email":"admin@example.com","password":"password123"}'
TOKEN=$(curl -s -X POST http://localhost:8000/auth/login -H 'Content-Type: application/json' -d "$LOGIN_JSON" | jq -r .access_token)
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8000/items
```

## 📈 Future Performance Roadmap

Full expanded roadmap with phased strategy: see [PERFORMANCE_ROADMAP.md](./PERFORMANCE_ROADMAP.md)

### Automated Recent Items MV Refresh

The materialized view `mv_recent_items` is refreshed by the `worker-beat` service every 10 minutes (configurable).

Environment variables:

- `ENABLE_MV_REFRESH=true`
- `RECENT_ITEMS_MV_REFRESH_MINUTES=10`

Tail logs:

```bash
docker-compose logs -f worker-beat
```

Windows PowerShell:

```powershell
./scripts/dev.ps1 beatlogs
```

The materialized view `mv_recent_items` is refreshed by the `worker-beat` service every 10 minutes (configurable):

Environment variables:

- `ENABLE_MV_REFRESH=true`
- `RECENT_ITEMS_MV_REFRESH_MINUTES=10`

Tail logs:

```bash
docker-compose logs -f worker-beat
```

Windows PowerShell:

```powershell
./scripts/dev.ps1 beatlogs
```

| Area                   | Strategy                                                | Notes                                          |
| ---------------------- | ------------------------------------------------------- | ---------------------------------------------- |
| Rolling 30‑day queries | Materialized view `mv_recent_items` refreshed every 10m | Avoid non-IMMUTABLE predicates in indexes      |
| Text relevance         | Add pgvector for semantic embedding search              | NLP service already produces embeddings        |
| Matching               | Precompute candidate blocks by geohash + category       | Store in auxiliary table or Redis cache        |
| Auditing scale         | Partition `audit_logs` monthly                          | Use native PG partitioning if volume >10M rows |
| Cleanup                | Background soft-delete purger                           | Convert to hard delete after retention window  |

Materialized view example (NOT yet applied):

```sql
CREATE MATERIALIZED VIEW mv_recent_items AS
SELECT id, status, category, created_at, location_point
FROM items
WHERE is_deleted = FALSE
   AND created_at > (NOW() - INTERVAL '30 days');

-- Refresh (cron / Celery beat)
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_recent_items;
```

## 🔍 Troubleshooting

| Symptom                                                     | Likely Cause                      | Fix                                                                         |
| ----------------------------------------------------------- | --------------------------------- | --------------------------------------------------------------------------- |
| `relation ... already exists` during migration              | Partial earlier failure           | `alembic downgrade base && alembic upgrade head` or use `reset_database.py` |
| `CREATE INDEX CONCURRENTLY cannot run inside a transaction` | Using CONCURRENTLY in Alembic txn | Remove `CONCURRENTLY` or use batch pattern / raw connection autocommit      |
| 401 on protected endpoints                                  | Missing Bearer token              | Obtain token via `/auth/login`                                              |
| Geospatial errors                                           | PostGIS extension missing         | Ensure migration 1 ran and DB user has privileges                           |

---

_This README section was auto-generated and curated to reflect the finalized migration & performance approach._

```

## �🔒 Security

- All passwords must be changed from defaults in production
- JWT_SECRET must be a secure random string (min 32 characters)
- Use HTTPS in production
- Enable coordinate fuzzing and masked chat
- Review and configure CORS_ORIGINS appropriately

## 📄 License

MIT License - see [LICENSE](LICENSE) file

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines and code of conduct.

## 📞 Support

For issues and questions:

- GitHub Issues: https://github.com/DATDSG/lost-found/issues
- Email: support@lostfound.com

## 🙏 Acknowledgments

Built with FastAPI, Next.js, Flutter, PostgreSQL, and powered by open-source AI models.
```
