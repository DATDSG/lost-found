import requests
import json

# Test login
response = requests.post(
    "http://localhost:8000/v1/auth/login",
    json={
        "email": "john.doe@email.com",
        "password": "password123"
    }
)

print(f"Status: {response.status_code}")
print(f"Response: {response.text}")

if response.status_code == 200:
    data = response.json()
    token = data["access_token"]
    print(f"Token: {token}")
    
    # Test reports endpoint
    headers = {"Authorization": f"Bearer {token}"}
    reports_response = requests.get("http://localhost:8000/v1/reports/reports/test", headers=headers)
    print(f"Reports Status: {reports_response.status_code}")
    print(f"Reports Response: {reports_response.text}")
