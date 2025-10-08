# 📝 Database Seeding Guide

## ✅ Admin User Created Successfully!

The admin user has been created directly in the database.

### 🔑 Login Credentials

**Admin Account:**

- **Email**: `admin@lostfound.com`
- **Password**: `Admin123!`

### 🌐 Access Points

- **API Documentation**: http://localhost:8000/docs
- **Interactive API**: http://localhost:8000/redoc
- **Health Check**: http://localhost:8000/health

## 📊 Next Steps

### 1. Test Admin Login

Visit http://localhost:8000/docs and click "Authorize" at the top right:

- Enter email: `admin@lostfound.com`
- Enter password: `Admin123!`

### 2. Create Additional Users

You can create more test users using the API `/v1/auth/register` endpoint:

```powershell
$user = @{
    email = "test@example.com"
    password = "Test123!"
    display_name = "Test User"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8000/v1/auth/register" `
    -Method Post `
    -Body $user `
    -ContentType "application/json"
```

### 3. Create Test Reports

Once logged in, you can:

1. Create lost item reports
2. Create found item reports
3. Test the matching algorithm
4. Upload images (if vision service is running)

## 🔧 Troubleshooting

### Issue: Cannot login with admin credentials

**Solution**: Re-run the admin creation script:

```powershell
powershell -ExecutionPolicy Bypass -File create_admin.ps1
```

### Issue: Need to reset password

**SQL Command**:

```sql
docker exec -it lost-found-db psql -U postgres -d lostfound -c "UPDATE users SET hashed_password = '\$2b\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/Lewwc.3a4q2gRRHpW' WHERE email = 'admin@lostfound.com';"
```

This resets the password to `Admin123!`.

## 📚 Available Scripts

1. **create_admin.ps1** - Creates admin user (✅ Already run)
2. **seed_database.ps1** - Seeds multiple test users via API (has schema issues currently)

## ⚠️ Known Issues

### User Registration API Error (500)

**Issue**: The `/v1/auth/register` endpoint returns a 500 error due to `updated_at` column being NULL.

**Root Cause**: Database schema expects `updated_at` to be NOT NULL, but the SQLAlchemy model has `onupdate=func.now()` which only sets the value on UPDATE, not INSERT.

**Temporary Solution**: Create users directly in database using SQL (like we did for admin user).

**Permanent Fix Needed**: Update the database migration to make `updated_at` nullable OR add a default value:

```sql
ALTER TABLE users ALTER COLUMN updated_at DROP NOT NULL;
-- OR
ALTER TABLE users ALTER COLUMN updated_at SET DEFAULT NOW();
```

## 📈 System Status

- ✅ Database: PostgreSQL 18 running
- ✅ API Service: Running on port 8000
- ✅ Admin User: Created and ready to use
- ⚠️ User Registration: Needs schema fix (low priority)
- ✅ Authentication: Working (tested with admin user)

---

**Last Updated**: October 8, 2025
**Status**: Ready for testing with admin account
