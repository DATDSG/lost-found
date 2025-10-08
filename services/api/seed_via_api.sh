#!/bin/bash
# Database Seeding Script - Uses API endpoints to seed data

echo "============================================================"
echo "Lost & Found Database Seeding via API"
echo "============================================================"
echo ""
echo "🌐 API Base URL: http://localhost:8000"
echo ""

# Function to create a user via API
create_user() {
    local email=$1
    local password=$2
    local display_name=$3
    
    echo "Creating user: $email..."
    curl -s -X POST "http://localhost:8000/api/v1/auth/register" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$email\",
            \"password\": \"$password\",
            \"display_name\": \"$display_name\"
        }" | jq -r '.id' || echo "Failed"
}

echo "Creating admin user..."
create_user "admin@lostfound.com" "Admin123!" "System Admin"

echo ""
echo "Creating test users..."
create_user "user1@example.com" "Test123!" "John Smith"
create_user "user2@example.com" "Test123!" "Jane Doe"
create_user "user3@example.com" "Test123!" "Bob Johnson"
create_user "user4@example.com" "Test123!" "Alice Williams"
create_user "user5@example.com" "Test123!" "Charlie Brown"

echo ""
echo "============================================================"
echo "✅ Database seeding completed!"
echo "============================================================"
echo ""
echo "🔑 Admin credentials:"
echo "   - Email: admin@lostfound.com"
echo "   - Password: Admin123!"
echo ""
echo "🔑 Test user credentials:"
echo "   - Email: user1@example.com through user5@example.com"
echo "   - Password: Test123!"
echo ""
echo "📚 You can now use these accounts to test the system!"
echo "📍 Login at: http://localhost:8000/docs"
echo ""
