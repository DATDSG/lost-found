# Quick Database Seeding - Creates one admin user directly in database
# This avoids the model/schema mismatch issues

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Creating Admin User in Database" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# SQL to create admin user
$sql = @"
INSERT INTO users (id, email, hashed_password, display_name, role, is_active, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    'admin@lostfound.com',
    '\$2b\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/Lewwc.3a4q2gRRHpW',
    'System Admin',
    'admin',
    true,
    NOW(),
    NOW()
)
ON CONFLICT (email) DO NOTHING;
"@

try {
    docker exec lost-found-db psql -U postgres -d lostfound -c $sql
    Write-Host ""
    Write-Host "Admin user created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Admin credentials:" -ForegroundColor Yellow
    Write-Host "   Email: admin@lostfound.com"
    Write-Host "   Password: Admin123!"
    Write-Host ""
    Write-Host "You can now login at: http://localhost:8000/docs" -ForegroundColor Cyan
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
