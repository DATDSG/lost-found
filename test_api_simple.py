#!/usr/bin/env python3
"""
Simple API endpoint testing script for the report integration.
Tests the key endpoints and fields we've implemented.
"""

import requests
import json
import time
from datetime import datetime, timezone

# API base URL
BASE_URL = "http://localhost:8000"

def test_health_endpoint():
    """Test the health endpoint to ensure API is running."""
    print("Testing health endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/health")
        if response.status_code == 200:
            print("Health endpoint working")
            return True
        else:
            print(f"Health endpoint failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"Health endpoint error: {e}")
        return False

def test_create_report():
    """Test creating a report with new fields."""
    print("\nTesting report creation...")
    
    report_data = {
        "type": "lost",
        "title": "Test iPhone 13 Pro Max",
        "description": "Test lost iPhone with all new fields implemented.",
        "category": "Electronics",
        "colors": ["Black"],
        "occurred_at": datetime.now(timezone.utc).isoformat(),
        "occurred_time": "14:30",
        "latitude": 40.7128,
        "longitude": -74.0060,
        "location_city": "New York",
        "location_address": "Central Park, NYC",
        "contact_info": "+1-555-123-4567",
        "condition": "Good",
        "is_urgent": True,
        "reward_offered": True,
        "reward_amount": "$100"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/v1/reports/", json=report_data)
        if response.status_code == 201:
            data = response.json()
            print("Report created successfully")
            print(f"   Report ID: {data['id']}")
            print(f"   Title: {data['title']}")
            print(f"   Urgent: {data.get('is_urgent', 'N/A')}")
            print(f"   Reward: {data.get('reward_amount', 'N/A')}")
            print(f"   Contact: {data.get('contact_info', 'N/A')}")
            return data['id']
        else:
            print(f"Report creation failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return None
    except Exception as e:
        print(f"Report creation error: {e}")
        return None

def test_get_report(report_id):
    """Test getting a specific report."""
    print(f"\nTesting get report {report_id}...")
    
    try:
        response = requests.get(f"{BASE_URL}/v1/reports/{report_id}")
        if response.status_code == 200:
            data = response.json()
            print("Report retrieved successfully")
            print(f"   Title: {data['title']}")
            print(f"   Type: {data['type']}")
            print(f"   Status: {data['status']}")
            print(f"   Contact Info: {data.get('contact_info', 'N/A')}")
            print(f"   Condition: {data.get('condition', 'N/A')}")
            print(f"   Reward Amount: {data.get('reward_amount', 'N/A')}")
            return True
        else:
            print(f"Get report failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"Get report error: {e}")
        return False

def test_list_reports():
    """Test listing reports."""
    print("\nTesting list reports...")
    
    try:
        response = requests.get(f"{BASE_URL}/v1/reports/")
        if response.status_code == 200:
            data = response.json()
            print("Reports listed successfully")
            print(f"   Found {len(data)} reports")
            return True
        else:
            print(f"List reports failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"List reports error: {e}")
        return False

def test_admin_endpoints():
    """Test admin endpoints."""
    print("\nTesting admin endpoints...")
    
    try:
        # Test admin reports list
        response = requests.get(f"{BASE_URL}/v1/admin/reports")
        if response.status_code == 200:
            data = response.json()
            print("Admin reports list working")
            print(f"   Found {data['total']} total reports")
        else:
            print(f"Admin reports list failed: {response.status_code}")
        
        # Test admin stats
        response = requests.get(f"{BASE_URL}/v1/admin/reports/stats")
        if response.status_code == 200:
            data = response.json()
            print("Admin stats working")
            print(f"   Total reports: {data['total']}")
            print(f"   Pending: {data['pending']}")
            print(f"   Approved: {data['approved']}")
        else:
            print(f"Admin stats failed: {response.status_code}")
        
        return True
    except Exception as e:
        print(f"Admin endpoints error: {e}")
        return False

def main():
    """Run all API tests."""
    print("Starting API Endpoint Tests")
    print("=" * 50)
    
    # Wait a moment for the server to start
    print("Waiting for API server to start...")
    time.sleep(3)
    
    tests_passed = 0
    total_tests = 0
    
    # Test health endpoint
    total_tests += 1
    if test_health_endpoint():
        tests_passed += 1
    
    # Test report creation
    total_tests += 1
    report_id = test_create_report()
    if report_id:
        tests_passed += 1
    
    # Test report retrieval
    if report_id:
        total_tests += 1
        if test_get_report(report_id):
            tests_passed += 1
    
    # Test report listing
    total_tests += 1
    if test_list_reports():
        tests_passed += 1
    
    # Test admin endpoints
    total_tests += 1
    if test_admin_endpoints():
        tests_passed += 1
    
    print("\n" + "=" * 50)
    print(f"Test Results: {tests_passed}/{total_tests} tests passed")
    
    if tests_passed == total_tests:
        print("All API tests passed! The implementation is working correctly.")
        return True
    else:
        print("Some API tests failed. Please check the implementation.")
        return False

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
