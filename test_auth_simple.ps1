# Test authentication endpoints
$apiUrl = "http://localhost:8000"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Testing Lost & Found Authentication" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Login with existing admin user
Write-Host "Test 1: Admin Login" -ForegroundColor Yellow
Write-Host "----------------------------------------"
try {
    $loginBody = @{
        email = "admin@lostfound.com"
        password = "Admin123!"
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "$apiUrl/v1/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    Write-Host "Success: Admin login works!" -ForegroundColor Green
    Write-Host "  Token preview: $($response.access_token.Substring(0, 30))..." -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "Failed: $_" -ForegroundColor Red
    Write-Host ""
}

# Test 2: Register a completely new user
Write-Host "Test 2: New User Registration" -ForegroundColor Yellow
Write-Host "----------------------------------------"
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$newEmail = "testuser$timestamp@example.com"
try {
    $registerBody = @{
        email = $newEmail
        password = "NewTest123!"
        display_name = "Test User $timestamp"
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "$apiUrl/v1/auth/register" -Method Post -Body $registerBody -ContentType "application/json"
    Write-Host "Success: User registration works!" -ForegroundColor Green
    Write-Host "  Email: $newEmail" -ForegroundColor Gray
    Write-Host "  Token preview: $($response.access_token.Substring(0, 30))..." -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "Failed: $_" -ForegroundColor Red
    Write-Host ""
}

# Test 3: Login with regular user
Write-Host "Test 3: Regular User Login" -ForegroundColor Yellow
Write-Host "----------------------------------------"
try {
    $loginBody = @{
        email = "user1@example.com"
        password = "Test123!"
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "$apiUrl/v1/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    Write-Host "Success: User login works!" -ForegroundColor Green
    Write-Host "  Token preview: $($response.access_token.Substring(0, 30))..." -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "Failed: $_" -ForegroundColor Red
    Write-Host ""
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Authentication tests completed!" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
