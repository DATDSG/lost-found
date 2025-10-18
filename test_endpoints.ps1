# Test all new admin endpoints

Write-Host "=== Getting Auth Token ===" -ForegroundColor Cyan
$body = @{
    email = 'admin@lostfound.com'
    password = 'Admin123!'
} | ConvertTo-Json

$response = Invoke-WebRequest -Uri 'http://localhost:8000/v1/auth/login' -Method POST -Body $body -ContentType 'application/json'
$token = ($response.Content | ConvertFrom-Json).access_token
Write-Host "✓ Token obtained" -ForegroundColor Green

$headers = @{
    Authorization = "Bearer $token"
}

Write-Host "`n=== Testing /v1/health ===" -ForegroundColor Cyan
try {
    $health = Invoke-WebRequest -Uri 'http://localhost:8000/v1/health'
    Write-Host "✓ Status: $($health.StatusCode)" -ForegroundColor Green
    $healthData = $health.Content | ConvertFrom-Json
    Write-Host "  Database: $($healthData.database)"
    Write-Host "  NLP Service: $($healthData.services.nlp)"
    Write-Host "  Vision Service: $($healthData.services.vision)"
} catch {
    Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Testing /v1/admin/users ===" -ForegroundColor Cyan
try {
    $users = Invoke-WebRequest -Uri 'http://localhost:8000/v1/admin/users?skip=0&limit=5' -Headers $headers
    Write-Host "✓ Status: $($users.StatusCode)" -ForegroundColor Green
    $usersData = $users.Content | ConvertFrom-Json
    Write-Host "  Total Users: $($usersData.total)"
    Write-Host "  Returned: $($usersData.users.Count) users"
} catch {
    Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Testing /v1/admin/matches ===" -ForegroundColor Cyan
try {
    $matches = Invoke-WebRequest -Uri 'http://localhost:8000/v1/admin/matches?skip=0&limit=5' -Headers $headers
    Write-Host "✓ Status: $($matches.StatusCode)" -ForegroundColor Green
    $matchesData = $matches.Content | ConvertFrom-Json
    Write-Host "  Total Matches: $($matchesData.total)"
    Write-Host "  Returned: $($matchesData.matches.Count) matches"
} catch {
    Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Testing /v1/admin/audit-logs ===" -ForegroundColor Cyan
try {
    $logs = Invoke-WebRequest -Uri 'http://localhost:8000/v1/admin/audit-logs?skip=0&limit=5' -Headers $headers
    Write-Host "✓ Status: $($logs.StatusCode)" -ForegroundColor Green
    $logsData = $logs.Content | ConvertFrom-Json
    Write-Host "  Total Logs: $($logsData.total)"
    Write-Host "  Returned: $($logsData.logs.Count) logs"
} catch {
    Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Testing /v1/admin/reports ===" -ForegroundColor Cyan
try {
    $reports = Invoke-WebRequest -Uri 'http://localhost:8000/v1/admin/reports?skip=0&limit=5' -Headers $headers
    Write-Host "✓ Status: $($reports.StatusCode)" -ForegroundColor Green
    $reportsData = $reports.Content | ConvertFrom-Json
    Write-Host "  Total Reports: $($reportsData.total)"
    Write-Host "  Returned: $($reportsData.reports.Count) reports"
} catch {
    Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== All Tests Complete ===" -ForegroundColor Cyan
