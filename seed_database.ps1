# Database Seeding Script - Uses API endpoints to seed data
# PowerShell version for Windows

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Lost & Found Database Seeding via API" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "API Base URL: http://localhost:8000" -ForegroundColor Yellow
Write-Host ""

# Function to create a user via API
function Create-User {
    param (
        [string]$email,
        [string]$password,
        [string]$displayName
    )
    
    Write-Host "Creating user: $email..." -ForegroundColor Gray
    
    $body = @{
        email = $email
        password = $password
        display_name = $displayName
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8000/v1/auth/register" `
            -Method Post `
            -Body $body `
            -ContentType "application/json"
        
        Write-Host "  Created: $($response.email)" -ForegroundColor Green
        return $response.id
    }
    catch {
        Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

Write-Host "Creating admin user..." -ForegroundColor Yellow
Create-User -email "admin@lostfound.com" -password "Admin123!" -displayName "System Admin"

Write-Host ""
Write-Host "Creating test users..." -ForegroundColor Yellow
Create-User -email "user1@example.com" -password "Test123!" -displayName "John Smith"
Create-User -email "user2@example.com" -password "Test123!" -displayName "Jane Doe"
Create-User -email "user3@example.com" -password "Test123!" -displayName "Bob Johnson"
Create-User -email "user4@example.com" -password "Test123!" -displayName "Alice Williams"
Create-User -email "user5@example.com" -password "Test123!" -displayName "Charlie Brown"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Database seeding completed!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Admin credentials:" -ForegroundColor Yellow
Write-Host "   - Email: admin@lostfound.com"
Write-Host "   - Password: Admin123!"
Write-Host ""
Write-Host "Test user credentials:" -ForegroundColor Yellow
Write-Host "   - Email: user1@example.com through user5@example.com"
Write-Host "   - Password: Test123!"
Write-Host ""
Write-Host "Test users created. You can now use these accounts to test the system!" -ForegroundColor Cyan
Write-Host "Login at: http://localhost:8000/docs" -ForegroundColor Cyan
Write-Host ""
