# Local Development Setup (Budget-Friendly)

This guide helps you run the Lost & Found system locally with minimal external API costs.

## 🎯 What You Get Without Expensive APIs

✅ **Full Core Functionality:**

- PostgreSQL database with PostGIS (geospatial features)
- Redis caching
- Item posting and searching
- Image uploads (local storage)
- Basic matching algorithms
- Admin dashboard

✅ **NLP Features (Recommended Investment):**

- Text similarity matching
- Multilingual support (Sinhala, Tamil, English)
- Semantic search capabilities

❌ **Disabled (Cost-Saving):**

- OAuth authentication (Google/Facebook login)
- Email notifications
- SMS notifications
- Cloud file storage (AWS S3)
- External AI services

## 🚀 Quick Start

### Prerequisites

- Docker Desktop installed and running
- Git (to clone the repository)

### Setup Steps

1. **Clone and navigate to the project:**

```bash
git clone https://github.com/DATDSG/lost-found.git
cd lost-found
```

2. **Run the local setup:**

```bash
# On Windows
start-local.bat

# Or manually
copy .env.local .env
cd deployment
docker-compose -f docker-compose-local.yml up --build
```

3. **Access the services:**

- **API Documentation:** http://localhost:8000/docs
- **Admin Panel:** http://localhost:3000 (if you build the frontend)
- **Database:** localhost:5432 (user: lostfound, password: lostfound)

## 🧪 Testing the Setup

Once running, you can test the API:

1. **Health Check:**

   ```bash
   curl http://localhost:8000/health
   ```

2. **Create Admin User:**
   The system will automatically create an admin user:

   - Email: admin@localhost
   - Password: admin123

3. **Test Item Creation:**
   ```bash
   curl -X POST "http://localhost:8000/api/v1/items" \
     -H "Content-Type: application/json" \
     -d '{
       "title": "Lost Phone",
       "description": "iPhone 12 lost in Colombo",
       "category": "electronics",
       "item_type": "lost",
       "location": {
         "latitude": 6.9271,
         "longitude": 79.8612,
         "address": "Colombo, Sri Lanka"
       }
     }'
   ```

## 💰 Future API Investments (When You Have Budget)

### Priority 1: Email Service (~$0-5/month)

```bash
# Add to .env when ready
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
ENABLE_EMAIL=true
```

### Priority 2: Cloud Storage (~$5-10/month)

```bash
# AWS S3 or DigitalOcean Spaces
S3_ENDPOINT_URL=https://s3.amazonaws.com
S3_ACCESS_KEY_ID=your-key
S3_SECRET_ACCESS_KEY=your-secret
S3_BUCKET=your-bucket
```

### Priority 3: OAuth Authentication (Free)

```bash
# Google OAuth (free)
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
ENABLE_OAUTH=true
```

## 🔧 NLP Investment Options

Since you mentioned you can invest in NLP, here are cost-effective options:

### Option 1: Local Models (Recommended)

- **Cost:** Free (uses Hugging Face models)
- **Models:** Runs locally in Docker
- **Languages:** Supports Sinhala, Tamil, English
- **Setup:** Already configured in docker-compose-local.yml

### Option 2: Hugging Face API (Budget-friendly)

- **Cost:** ~$1-10/month depending on usage
- **Setup:** Add to .env:

```bash
HUGGINGFACE_API_KEY=your-hf-api-key
HUGGINGFACE_MODEL=sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2
```

### Option 3: OpenAI Embeddings (More expensive)

- **Cost:** ~$20-100/month depending on usage
- **Better quality** but higher cost

## 📊 Database Management

Access PostgreSQL directly:

```bash
# Connect to database
docker exec -it lf_database_local psql -U lostfound -d lostfound

# View tables
\dt

# View items
SELECT title, description, item_type FROM items LIMIT 5;
```

## 🐛 Troubleshooting

### Services won't start:

```bash
# Check Docker is running
docker --version

# Check port conflicts
netstat -an | findstr ":5432"
netstat -an | findstr ":8000"

# Restart from scratch
docker-compose -f docker-compose-local.yml down -v
docker-compose -f docker-compose-local.yml up --build
```

### Database connection issues:

1. Ensure PostgreSQL container is healthy:

   ```bash
   docker logs lf_database_local
   ```

2. Test connection:
   ```bash
   docker exec lf_database_local pg_isready -U lostfound -d lostfound
   ```

## 📈 Scaling Up Later

When you have more budget:

1. Enable email notifications for user engagement
2. Add cloud storage for better image handling
3. Implement OAuth for easier user onboarding
4. Add SMS notifications for critical alerts
5. Use managed database services for production

This setup gives you a fully functional lost & found system with the most important features while keeping costs minimal!
