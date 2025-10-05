# Quick Start Guide

Get the Lost & Found system running in 5 minutes!

## Prerequisites

- Docker & Docker Compose installed
- OR Python 3.11+, Node.js 18+, PostgreSQL 15+, Redis

## Option 1: Docker (Recommended)

1. **Clone and configure**

   ```bash
   git clone https://github.com/DATDSG/lost-found.git
   cd lost-found
   cp .env.example .env
   ```

2. **Start all services**

   ```bash
   docker-compose up -d
   ```

3. **Initialize MinIO bucket** (first time only)

   - Open http://localhost:9001
   - Login: minioadmin / minioadmin
   - Create bucket named `media`
   - Set public read policy

4. **Access the application**
   - API: http://localhost:8000/docs
   - Admin Panel: http://localhost:3000
   - Default admin: admin@example.com / admin123

## Option 2: Manual Setup

1. **Clone repository**

   ```bash
   git clone https://github.com/DATDSG/lost-found.git
   cd lost-found
   ```

2. **Setup PostgreSQL**

   ```bash
   createdb lostfound
   psql -d lostfound -c "CREATE EXTENSION postgis;"
   ```

3. **Install and start Redis**

   ```bash
   redis-server
   ```

4. **Setup API**

   ```bash
   cd backend/api
   pip install -r requirements.txt
   cp .env.example .env
   # Edit .env with your database credentials
   alembic upgrade head
   uvicorn app.main:app --reload --port 8000
   ```

5. **Setup Web Admin** (new terminal)

   ```bash
   cd frontend/web-admin
   npm install
   cp .env.example .env.local
   # Edit NEXT_PUBLIC_API_URL=http://localhost:8000
   npm run dev
   ```

6. **Access application**
   - API: http://localhost:8000/docs
   - Admin: http://localhost:3000

## Optional: Enable AI Features

To enable NLP and Vision services:

1. **Update .env**

   ```bash
   NLP_ON=true
   CV_ON=true
   ```

2. **Start NLP Service**

   ```bash
   cd backend/nlp
   pip install -r requirements.txt
   python server/main.py
   ```

3. **Start Vision Service**
   ```bash
   cd backend/vision
   pip install -r requirements.txt
   python server/main.py
   ```

## Mobile App Setup

```bash
cd frontend/mobile
flutter pub get
flutter run
```

## Common Issues

### Port conflicts

If ports 8000, 3000, 5432, 6379, 9000 are in use, either:

- Stop conflicting services
- Change ports in docker-compose.yml or .env

### Database connection errors

- Ensure PostgreSQL is running
- Check DATABASE_URL in .env
- Verify PostGIS extension is installed

### API not accessible

- Check if all services are running: `docker-compose ps`
- View logs: `docker-compose logs -f api`

## Next Steps

1. **Change default passwords** in .env
2. **Create test users** via admin panel
3. **Post test items** to try matching
4. **Explore API** at http://localhost:8000/docs
5. **Read full documentation** in README.md

## Need Help?

- Check README.md for detailed documentation
- View service-specific READMEs in backend/ and frontend/
- Report issues: https://github.com/DATDSG/lost-found/issues
