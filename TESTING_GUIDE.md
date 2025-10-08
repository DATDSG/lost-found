# 🧪 Complete Testing Guide - Lost & Found Application

## Date: October 8, 2025

---

## ✅ **Pre-Test Verification**

All services are healthy and ready for testing:

- ✅ API: http://localhost:8000/docs
- ✅ Database: 11 tables created
- ✅ NLP Service: Ready
- ✅ Vision Service: Ready
- ✅ Grafana: http://localhost:3000

---

## 📋 **Test Plan Overview**

### **1. API Endpoint Testing** (Swagger UI)

### **2. User Registration & Authentication**

### **3. Upload Images & Create Reports**

### **4. Test Matching Algorithm**

### **5. Monitor Performance (Grafana)**

### **6. Test Fast Rebuilds**

---

## 1️⃣ **API Endpoint Testing via Swagger UI**

### **Access Swagger UI**

🌐 **URL**: http://localhost:8000/docs

### **Available Endpoints to Test**

#### **Health & Status**

```bash
GET /health
- No authentication required
- Returns service status and health checks
```

#### **User Management**

```bash
POST /api/v1/users/register
- Create new user account
- Required: email, password, name

POST /api/v1/users/login
- Login and get JWT token
- Required: email, password
- Returns: access_token

GET /api/v1/users/me
- Get current user profile
- Requires: Bearer token
```

#### **Report Management**

```bash
POST /api/v1/reports
- Create lost or found report
- Required: title, description, type (lost/found)
- Optional: category, location, date

GET /api/v1/reports
- List all reports
- Supports filtering and pagination

GET /api/v1/reports/{id}
- Get specific report details

PUT /api/v1/reports/{id}
- Update report
- Requires: owner authentication

DELETE /api/v1/reports/{id}
- Delete report
- Requires: owner authentication
```

#### **Media/Image Upload**

```bash
POST /api/v1/media/upload
- Upload images for reports
- Supports: JPG, PNG, WEBP
- Max size: 10MB
- EXIF data stripped automatically

GET /api/v1/media/{id}
- Retrieve uploaded image
```

#### **Matching Algorithm**

```bash
POST /api/v1/matches/find
- Find matches for a report
- Uses multi-modal matching:
  * Text similarity (45%)
  * Image similarity (35%)
  * Geo proximity (15%)
  * Time proximity (5%)

GET /api/v1/matches/{report_id}
- Get all matches for a report
```

---

## 2️⃣ **Step-by-Step: Register User & Login**

### **Step 1: Register a Test User**

**Endpoint**: `POST /api/v1/users/register`

**Request Body**:

```json
{
  "email": "test@example.com",
  "password": "SecurePass123!",
  "name": "Test User",
  "phone": "+1234567890"
}
```

**Expected Response** (201 Created):

```json
{
  "id": "uuid-here",
  "email": "test@example.com",
  "name": "Test User",
  "created_at": "2025-10-08T15:12:00Z",
  "is_active": true
}
```

### **Step 2: Login to Get Token**

**Endpoint**: `POST /api/v1/users/login`

**Request Body**:

```json
{
  "email": "test@example.com",
  "password": "SecurePass123!"
}
```

**Expected Response** (200 OK):

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 3600
}
```

### **Step 3: Authorize in Swagger**

1. Copy the `access_token` from login response
2. Click **"Authorize"** button (🔓 icon) at top of Swagger UI
3. Enter: `Bearer <your-token-here>`
4. Click **"Authorize"**
5. You're now authenticated! ✅

---

## 3️⃣ **Upload Images & Create Reports**

### **Test Scenario: Lost Phone Report**

#### **Step 1: Prepare Test Image**

Create a test image or use any image file:

- Supported formats: JPG, PNG, WEBP
- Max size: 10MB
- Image will be processed by Vision service

#### **Step 2: Upload Image**

**Endpoint**: `POST /api/v1/media/upload`

**Using Swagger UI**:

1. Click on `/api/v1/media/upload` endpoint
2. Click **"Try it out"**
3. Click **"Choose File"** and select image
4. Add optional parameters:
   ```json
   {
     "category": "lost_item",
     "description": "Lost iPhone 15 Pro"
   }
   ```
5. Click **"Execute"**

**Expected Response**:

```json
{
  "id": "media-uuid-123",
  "url": "/media/images/2025/10/08/filename.jpg",
  "thumbnail_url": "/media/thumbnails/2025/10/08/filename_thumb.jpg",
  "width": 1920,
  "height": 1080,
  "size": 2457600,
  "format": "jpeg",
  "hash": "d4f5e6a7b8c9...",
  "created_at": "2025-10-08T15:15:00Z"
}
```

#### **Step 3: Create Lost Report**

**Endpoint**: `POST /api/v1/reports`

**Request Body**:

```json
{
  "type": "lost",
  "title": "Lost iPhone 15 Pro",
  "description": "Lost my iPhone 15 Pro (Blue Titanium) near Central Park. Has a distinctive case with stickers.",
  "category": "electronics",
  "color": "blue",
  "location": {
    "address": "Central Park, New York, NY",
    "latitude": 40.785091,
    "longitude": -73.968285
  },
  "date_lost": "2025-10-08T10:00:00Z",
  "media_ids": ["media-uuid-123"],
  "contact_preference": "email",
  "tags": ["iphone", "apple", "phone", "blue"]
}
```

**Expected Response**:

```json
{
  "id": "report-uuid-456",
  "type": "lost",
  "title": "Lost iPhone 15 Pro",
  "description": "...",
  "status": "active",
  "category": "electronics",
  "media": [
    {
      "id": "media-uuid-123",
      "url": "/media/images/...",
      "is_primary": true
    }
  ],
  "location": {
    "address": "Central Park, New York, NY",
    "coordinates": [40.785091, -73.968285]
  },
  "created_at": "2025-10-08T15:16:00Z",
  "user": {
    "id": "user-uuid",
    "name": "Test User"
  },
  "match_count": 0
}
```

#### **Step 4: Create Found Report (Match Test)**

**Request Body**:

```json
{
  "type": "found",
  "title": "Found Blue iPhone",
  "description": "Found an iPhone 15 Pro in blue near Central Park. Has case with stickers on it.",
  "category": "electronics",
  "color": "blue",
  "location": {
    "address": "Central Park South, New York, NY",
    "latitude": 40.767095,
    "longitude": -73.981927
  },
  "date_found": "2025-10-08T14:00:00Z",
  "media_ids": ["media-uuid-789"],
  "contact_preference": "phone",
  "tags": ["iphone", "found", "blue", "central park"]
}
```

---

## 4️⃣ **Test Matching Algorithm**

### **Automatic Matching**

The system automatically runs matching when a report is created. The algorithm uses:

**Matching Weights**:

- 🔤 **Text Similarity**: 45% (NLP analysis)
- 🖼️ **Image Similarity**: 35% (Vision analysis)
- 📍 **Geo Proximity**: 15% (location matching)
- 🕐 **Time Proximity**: 5% (date matching)

**Minimum Match Score**: 0.65 (65%)

### **Step 1: Trigger Manual Match**

**Endpoint**: `POST /api/v1/matches/find`

**Request Body**:

```json
{
  "report_id": "report-uuid-456"
}
```

**Expected Response**:

```json
{
  "report_id": "report-uuid-456",
  "matches": [
    {
      "matched_report_id": "report-uuid-789",
      "score": 0.87,
      "confidence": "high",
      "breakdown": {
        "text_score": 0.92,
        "image_score": 0.85,
        "geo_score": 0.78,
        "time_score": 0.95
      },
      "matched_report": {
        "id": "report-uuid-789",
        "type": "found",
        "title": "Found Blue iPhone",
        "media": [...],
        "location": {...}
      },
      "created_at": "2025-10-08T15:20:00Z"
    }
  ],
  "total_matches": 1,
  "processing_time_ms": 234
}
```

### **Step 2: Review Match Details**

**Endpoint**: `GET /api/v1/matches/{report_id}`

This shows all matches with detailed scoring:

- **Text matching**: NLP service analyzes descriptions
- **Image matching**: Vision service compares images
- **Geo matching**: Distance calculation (within 5km)
- **Time matching**: Date proximity (within 30 days)

### **Step 3: Test Edge Cases**

**Create reports to test**:

1. ✅ **High match**: Similar item, same location, same day
2. ⚠️ **Medium match**: Similar item, different location
3. ❌ **No match**: Different item category

---

## 5️⃣ **Monitor Performance with Grafana**

### **Access Grafana Dashboard**

🌐 **URL**: http://localhost:3000

**Login**:

- Username: `admin`
- Password: `admin`
- (You'll be prompted to change password)

### **Step 1: Verify Data Sources**

1. Click **⚙️ Configuration** → **Data Sources**
2. Verify these are connected:
   - ✅ **Prometheus** (metrics)
   - ✅ **Loki** (logs)

### **Step 2: Import Dashboards**

#### **Create API Performance Dashboard**

1. Click **+** → **Import**
2. Create new dashboard with panels:

**Panel 1: Request Rate**

```promql
# Query for Prometheus
rate(http_requests_total[5m])
```

**Panel 2: Response Time**

```promql
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

**Panel 3: Error Rate**

```promql
rate(http_requests_total{status=~"5.."}[5m])
```

**Panel 4: Database Connections**

```promql
pg_stat_database_numbackends
```

### **Step 3: Monitor During Load Test**

Run load test while watching Grafana:

```bash
# Install Apache Bench (if not installed)
# For Windows: Download from https://www.apachelounge.com/

# Run 1000 requests with 10 concurrent users
ab -n 1000 -c 10 http://localhost:8000/health

# Or use curl in a loop
for /L %i in (1,1,100) do curl http://localhost:8000/health
```

**What to observe in Grafana**:

- 📈 Request rate increases
- ⏱️ Response times stay low
- ❌ Error rate stays at 0%
- 🔄 Redis cache hit rate

### **Step 4: View Application Logs**

1. Click **🔍 Explore**
2. Select **Loki** data source
3. Query examples:

```logql
# All API logs
{container_name="lost-found-api"}

# Errors only
{container_name="lost-found-api"} |= "ERROR"

# NLP processing
{container_name="lost-found-nlp"}

# Matching algorithm
{container_name="lost-found-api"} |= "matching"
```

---

## 6️⃣ **Test Fast Rebuilds (10-20x Faster!)**

### **Baseline: Before Optimization**

- Full rebuild: 5-10 minutes
- Code change rebuild: 5-10 minutes (no caching)

### **Now: After Optimization**

- Full rebuild: 2-3 minutes (first time)
- Code change rebuild: **10-30 seconds** ⚡

### **Test Scenario: Modify API Code**

#### **Step 1: Make a Code Change**

Edit `services/api/app/main.py`:

```python
# Add a new endpoint
@app.get("/api/v1/test")
async def test_endpoint():
    return {"message": "Testing fast rebuild!", "timestamp": datetime.now()}
```

#### **Step 2: Rebuild ONLY API Service**

```bash
# Navigate to compose directory
cd c:\Users\td123\OneDrive\Documents\GitHub\lost-found\infra\compose

# Rebuild API service (uses cached layers!)
docker-compose build api

# Time it - should be 10-30 seconds!
```

**What happens**:

1. ✅ Dependencies layer: **CACHED** (not reinstalled)
2. ✅ System packages: **CACHED** (not reinstalled)
3. 🔄 Code copy: **UPDATED** (only new code)
4. ✅ Final image: **BUILT** (in seconds!)

#### **Step 3: Restart Service**

```bash
docker-compose up -d api
```

#### **Step 4: Test New Endpoint**

```bash
curl http://localhost:8000/api/v1/test
```

**Expected**: New endpoint works immediately! 🎉

---

## 📊 **Performance Comparison**

### **Before Optimization**

```
Code Change → Full Rebuild → 5-10 min → Deploy → Test
Total Time: ~10 minutes per change
```

### **After Optimization**

```
Code Change → Smart Rebuild → 10-30 sec → Deploy → Test
Total Time: ~30 seconds per change
```

**Speed Improvement**: **10-20x faster!** 🚀

---

## 🧪 **Comprehensive Test Checklist**

### **API Testing** ✅

- [ ] Health endpoint responds
- [ ] Swagger UI loads
- [ ] User registration works
- [ ] User login returns JWT token
- [ ] Authenticated endpoints work
- [ ] Create report with image
- [ ] Update report
- [ ] Delete report
- [ ] List reports with filters

### **Image Processing** ✅

- [ ] Upload JPG image
- [ ] Upload PNG image
- [ ] Image is compressed
- [ ] Thumbnail generated
- [ ] EXIF data stripped
- [ ] Image hash calculated
- [ ] Vision service processes image

### **Matching Algorithm** ✅

- [ ] Text matching works (NLP)
- [ ] Image matching works (Vision)
- [ ] Geo matching works
- [ ] Time matching works
- [ ] Combined score calculated
- [ ] High confidence matches shown
- [ ] No matches for different categories

### **Database** ✅

- [ ] 11 tables exist
- [ ] pgvector extension works
- [ ] Queries are fast
- [ ] Transactions work
- [ ] Data persists across restarts

### **Monitoring** ✅

- [ ] Prometheus scrapes metrics
- [ ] Loki receives logs
- [ ] Grafana shows dashboards
- [ ] Alerts can be configured
- [ ] Real-time monitoring works

### **Performance** ✅

- [ ] API response < 100ms
- [ ] Image upload < 2s
- [ ] Matching query < 500ms
- [ ] Redis caching works
- [ ] Code rebuild < 30s

---

## 🎯 **Advanced Testing Scenarios**

### **Scenario 1: Multi-User Workflow**

1. Register 3 users
2. User A creates lost report
3. User B creates found report (similar)
4. User C creates found report (different)
5. Verify User A sees match with User B only

### **Scenario 2: Image Similarity**

1. Upload 3 images of same item
2. Upload 3 images of different items
3. Verify Vision service groups similar images
4. Verify match scores reflect similarity

### **Scenario 3: Geographic Matching**

1. Create reports at same location
2. Create reports 2km apart
3. Create reports 10km apart
4. Verify geo_score decreases with distance

### **Scenario 4: Load Testing**

```bash
# Install k6 (modern load testing tool)
# https://k6.io/docs/getting-started/installation/

# Create load test script (load-test.js)
import http from 'k6/http';
import { check } from 'k6';

export let options = {
  stages: [
    { duration: '30s', target: 10 },
    { duration: '1m', target: 50 },
    { duration: '30s', target: 0 },
  ],
};

export default function () {
  let res = http.get('http://localhost:8000/health');
  check(res, { 'status is 200': (r) => r.status === 200 });
}

# Run load test
k6 run load-test.js
```

### **Scenario 5: Rebuild Speed Test**

```bash
# Time before optimization
time docker-compose build api  # Would take 5-10 min

# Time after optimization
Measure-Command { docker-compose build api }
# Should take 10-30 seconds!
```

---

## 📈 **Expected Results**

### **API Performance**

- ✅ Health check: < 50ms
- ✅ Login: < 200ms
- ✅ Create report: < 500ms
- ✅ Upload image: < 2s (depends on size)
- ✅ Find matches: < 500ms

### **Service Health**

- ✅ API uptime: 99.9%
- ✅ Database connections: Stable
- ✅ Redis hit rate: > 80%
- ✅ NLP processing: < 300ms
- ✅ Vision processing: < 400ms

### **Build Performance**

- ✅ First build: 2-3 minutes
- ✅ Code change: 10-30 seconds
- ✅ Dependency change: 1-2 minutes
- ✅ Full rebuild: 2-3 minutes

---

## 🐛 **Troubleshooting**

### **Issue: Swagger UI not loading**

```bash
# Check API logs
docker-compose logs api

# Verify API is running
docker-compose ps api

# Restart API
docker-compose restart api
```

### **Issue: Image upload fails**

```bash
# Check media volume
docker volume inspect lost-found-media

# Check Vision service
docker-compose logs vision

# Verify file size < 10MB
```

### **Issue: No matches found**

```bash
# Check NLP service
docker-compose logs nlp

# Verify reports exist
curl http://localhost:8000/api/v1/reports

# Check matching scores
docker-compose logs api | grep "matching"
```

### **Issue: Slow rebuild**

```bash
# Clear build cache (if needed)
docker-compose build --no-cache api

# Verify multi-stage build
docker history compose-api

# Check Dockerfile
cat services/api/Dockerfile
```

---

## 🎊 **Testing Complete Checklist**

When you complete all tests, you should have:

- ✅ Created and tested user accounts
- ✅ Uploaded images successfully
- ✅ Created lost & found reports
- ✅ Verified matching algorithm works
- ✅ Monitored performance in Grafana
- ✅ Tested fast rebuilds (10-20x improvement)
- ✅ Verified all services are healthy
- ✅ Confirmed data persists across restarts
- ✅ Checked logs in Grafana/Loki
- ✅ Validated API documentation

---

## 🎉 **Success Criteria**

Your system is **production-ready** if:

1. ✅ All API endpoints respond correctly
2. ✅ Image upload and processing works
3. ✅ Matching algorithm returns results
4. ✅ Grafana shows real-time metrics
5. ✅ Code rebuilds in < 30 seconds
6. ✅ No errors in logs
7. ✅ All services stay healthy
8. ✅ Database queries are fast
9. ✅ Redis caching is effective
10. ✅ Load tests pass without errors

---

## 📞 **Next Steps After Testing**

1. **Production Deployment**

   - Update environment variables
   - Configure production database
   - Set up SSL/TLS certificates
   - Configure domain names

2. **Security Hardening**

   - Enable rate limiting
   - Set up WAF (Web Application Firewall)
   - Configure CORS properly
   - Enable audit logging

3. **Monitoring & Alerts**

   - Set up Grafana alerts
   - Configure email notifications
   - Monitor error rates
   - Track user metrics

4. **Performance Optimization**
   - Add CDN for media files
   - Optimize database queries
   - Tune Redis cache
   - Scale services horizontally

---

**Generated**: October 8, 2025, 15:12 IST  
**Status**: 🟢 Ready for Testing  
**Estimated Testing Time**: 30-60 minutes  
**Difficulty**: 🟢 Beginner-Friendly
