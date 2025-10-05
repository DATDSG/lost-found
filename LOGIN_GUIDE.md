# Login Credentials & Testing Guide

## ✅ Authentication Fixed!

The login issue has been resolved. A missing `timedelta` import was causing authentication to fail.

## Available Accounts

### Admin Account

- **Email**: `admin@example.com`
- **Password**: `password123`
- **Permissions**: Full admin access

### Regular User Account

- **Email**: `user@example.com`
- **Password**: `password123`
- **Permissions**: Standard user access

## Login via Web Admin

1. Open your browser and navigate to: http://localhost:3000/
2. You should see a login page
3. Enter credentials:
   - Email: `admin@example.com`
   - Password: `password123`
4. Click "Login" or submit the form

## Login via API (for testing)

### Get Access Token

```bash
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "password123"
  }'
```

**Response:**

```json
{
  "access_token": "eyJhbGci...",
  "token_type": "bearer"
}
```

### Use Token for Authenticated Requests

```bash
curl http://localhost:8000/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

**Response:**

```json
{
  "id": 3,
  "email": "admin@example.com",
  "full_name": "Admin User",
  "is_superuser": true
}
```

## Testing Items Endpoint

```bash
# Get items (requires authentication)
curl http://localhost:8000/items \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## Troubleshooting

If you still get "Invalid credentials":

1. Clear browser cookies/cache
2. Make sure you're using the exact credentials above
3. Check API logs: `docker-compose logs api --tail=50`
4. Verify API is running: `curl http://localhost:8000/healthz`

## What Was Fixed

1. **Missing Import**: Added `from datetime import timedelta` to `auth.py`
2. **Duplicate Logic**: Cleaned up redundant password verification
3. **Token Generation**: Fixed access token expiration handling

The system is now fully operational! 🎉
