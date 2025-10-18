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
    Write-Host "✓ Login successful!" -ForegroundColor Green
    Write-Host "  Access Token: $($response.access_token.Substring(0, 50))..." -ForegroundColor Gray
    Write-Host "  Refresh Token: $($response.refresh_token.Substring(0, 50))..." -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "✗ Login failed: $_" -ForegroundColor Red
}

# Test 2: Login with test user
Write-Host "Test 2: Regular User Login" -ForegroundColor Yellow
Write-Host "----------------------------------------"
try {
    $loginBody = @{
        email = "user1@example.com"
        password = "Test123!"
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "$apiUrl/v1/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    Write-Host "✓ Login successful!" -ForegroundColor Green
    Write-Host "  Access Token: $($response.access_token.Substring(0, 50))..." -ForegroundColor Gray
    Write-Host "  Refresh Token: $($response.refresh_token.Substring(0, 50))..." -ForegroundColor Gray
    Write-Host ""
    
    # Save token for next test
    $global:accessToken = $response.access_token
} catch {
    Write-Host "✗ Login failed: $_" -ForegroundColor Red
}

# Test 3: Register a completely new user
Write-Host "Test 3: New User Registration" -ForegroundColor Yellow
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
    Write-Host "✓ Registration successful!" -ForegroundColor Green
    Write-Host "  Email: $newEmail" -ForegroundColor Gray
    Write-Host "  Access Token: $($response.access_token.Substring(0, 50))..." -ForegroundColor Gray
    Write-Host "  Refresh Token: $($response.refresh_token.Substring(0, 50))..." -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "✗ Registration failed: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
        $result = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($result)
        $reader.BaseStream.Position = 0
        $responseBody = $reader.ReadToEnd()
        Write-Host "  Error details: $responseBody" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Authentication tests completed!" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
