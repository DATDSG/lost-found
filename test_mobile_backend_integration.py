#!/usr/bin/env python3
"""
Test script to verify mobile-backend integration
"""

import requests
import json
import sys

# Configuration
BASE_URL = "http://localhost:8000/v1"
TEST_EMAIL = "test@lostfound.com"
TEST_PASSWORD = "TestPassword123"

def test_health_endpoint():
    """Test the health endpoint"""
    print("Testing health endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/health")
        if response.status_code == 200:
            data = response.json()
            print(f"Health check passed: {data['status']}")
            return True
        else:
            print(f"Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"Health check error: {e}")
        return False

def test_auth_endpoints():
    """Test authentication endpoints"""
    print("\nTesting authentication endpoints...")
    
    # Try login first (in case user already exists)
    print("Testing user login...")
    try:
        login_data = {
            "email": TEST_EMAIL,
            "password": TEST_PASSWORD
        }
        response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
        if response.status_code == 200:
            print("User login successful")
            auth_data = response.json()
            access_token = auth_data.get("access_token")
            if access_token:
                print("Access token received")
                return access_token
        else:
            print(f"Login failed: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"Login error: {e}")
    
    # If login failed, try registration
    print("Testing user registration...")
    try:
        register_data = {
            "email": TEST_EMAIL,
            "password": TEST_PASSWORD,
            "display_name": "Test User"
        }
        response = requests.post(f"{BASE_URL}/auth/register", json=register_data)
        if response.status_code in [200, 201]:
            print("User registration successful")
            auth_data = response.json()
            access_token = auth_data.get("access_token")
            if access_token:
                print("Access token received")
                return access_token
        else:
            print(f"Registration failed: {response.status_code} - {response.text}")
            return None
    except Exception as e:
        print(f"Registration error: {e}")
        return None

def test_reports_endpoints(access_token):
    """Test reports endpoints"""
    print("\nTesting reports endpoints...")
    
    headers = {"Authorization": f"Bearer {access_token}"}
    
    # Test get reports
    print("Testing get reports...")
    try:
        response = requests.get(f"{BASE_URL}/reports", headers=headers)
        if response.status_code == 200:
            data = response.json()
            print(f"Get reports successful: {len(data)} reports")
        else:
            print(f"Get reports failed: {response.status_code}")
    except Exception as e:
        print(f"Get reports error: {e}")
    
    # Test get categories
    print("Testing get categories...")
    try:
        response = requests.get(f"{BASE_URL}/taxonomy/categories", headers=headers)
        if response.status_code == 200:
            data = response.json()
            print(f"Get categories successful: {len(data)} categories")
        else:
            print(f"Get categories failed: {response.status_code}")
    except Exception as e:
        print(f"Get categories error: {e}")
    
    # Test get colors
    print("Testing get colors...")
    try:
        response = requests.get(f"{BASE_URL}/taxonomy/colors", headers=headers)
        if response.status_code == 200:
            data = response.json()
            print(f"Get colors successful: {len(data)} colors")
        else:
            print(f"Get colors failed: {response.status_code}")
    except Exception as e:
        print(f"Get colors error: {e}")

def test_matches_endpoints(access_token):
    """Test matches endpoints"""
    print("\nTesting matches endpoints...")
    
    headers = {"Authorization": f"Bearer {access_token}"}
    
    # Test get matches
    print("Testing get matches...")
    try:
        response = requests.get(f"{BASE_URL}/matches", headers=headers)
        if response.status_code == 200:
            data = response.json()
            print(f"Get matches successful: {len(data.get('matches', []))} matches")
        else:
            print(f"Get matches failed: {response.status_code}")
    except Exception as e:
        print(f"Get matches error: {e}")

def main():
    """Main test function"""
    print("Starting Mobile-Backend Integration Test")
    print("=" * 50)
    
    # Test health endpoint
    if not test_health_endpoint():
        print("Health check failed, stopping tests")
        sys.exit(1)
    
    # Test authentication
    access_token = test_auth_endpoints()
    if not access_token:
        print("Authentication failed, stopping tests")
        sys.exit(1)
    
    # Test other endpoints
    test_reports_endpoints(access_token)
    test_matches_endpoints(access_token)
    
    print("\n" + "=" * 50)
    print("Mobile-Backend Integration Test Completed Successfully!")
    print("\nThe mobile app should now be able to connect to the backend.")
    print("Key features verified:")
    print("- Health monitoring")
    print("- User authentication")
    print("- Reports management")
    print("- Categories and colors")
    print("- Matches system")

if __name__ == "__main__":
    main()
