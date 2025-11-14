#!/usr/bin/env python3
"""
Comprehensive API endpoint testing script for the report integration.
Tests all the new endpoints and fields we've implemented.
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

def test_create_lost_report():
    """Test creating a lost item report with all new fields."""
    print("\nTesting lost item report creation...")
    
    lost_report_data = {
        "type": "lost",
        "title": "iPhone 13 Pro Max - Lost",
        "description": "Lost my iPhone 13 Pro Max with a black case. Has a small crack on the screen. Last seen near Central Park.",
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
        response = requests.post(f"{BASE_URL}/v1/reports/", json=lost_report_data)
        if response.status_code == 201:
            data = response.json()
            print("Lost item report created successfully")
            print(f"   Report ID: {data['id']}")
            print(f"   Title: {data['title']}")
            print(f"   Urgent: {data['is_urgent']}")
            print(f"   Reward: {data['reward_amount']}")
            return data['id']
        else:
            print(f"Lost item report creation failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return None
    except Exception as e:
        print(f"Lost item report creation error: {e}")
        return None

def test_create_found_report():
    """Test creating a found item report with all new fields."""
    print("\nTesting found item report creation...")
    
    found_report_data = {
        "type": "found",
        "title": "Black iPhone 13 - Found",
        "description": "Found a black iPhone 13 near the fountain. Screen is cracked but functional. Battery was dead when found.",
        "category": "Electronics",
        "colors": ["Black"],
        "occurred_at": datetime.now(timezone.utc).isoformat(),
        "occurred_time": "15:45",
        "latitude": 40.7589,
        "longitude": -73.9851,
        "location_city": "New York",
        "location_address": "Times Square, NYC",
        "contact_info": "founder@example.com",
        "additional_info": "Phone was found near the fountain. Battery was dead when found.",
        "condition": "Fair",
        "safety_status": "Safe",
        "is_safe": True,
        "reward_offered": False
    }
    
    try:
        response = requests.post(f"{BASE_URL}/v1/reports/", json=found_report_data)
        if response.status_code == 201:
            data = response.json()
            print("✅ Found item report created successfully")
            print(f"   Report ID: {data['id']}")
            print(f"   Title: {data['title']}")
            print(f"   Safety Status: {data['safety_status']}")
            print(f"   Additional Info: {data['additional_info']}")
            return data['id']
        else:
            print(f"❌ Found item report creation failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return None
    except Exception as e:
        print(f"❌ Found item report creation error: {e}")
        return None

def test_get_report(report_id):
    """Test getting a specific report."""
    print(f"\nTesting get report {report_id}...")
    
    try:
        response = requests.get(f"{BASE_URL}/v1/reports/{report_id}")
        if response.status_code == 200:
            data = response.json()
            print("✅ Report retrieved successfully")
            print(f"   Title: {data['title']}")
            print(f"   Type: {data['type']}")
            print(f"   Status: {data['status']}")
            print(f"   Contact Info: {data['contact_info']}")
            return True
        else:
            print(f"❌ Get report failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Get report error: {e}")
        return False

def test_list_reports():
    """Test listing reports."""
    print("\nTesting list reports...")
    
    try:
        response = requests.get(f"{BASE_URL}/v1/reports/")
        if response.status_code == 200:
            data = response.json()
            print("✅ Reports listed successfully")
            print(f"   Found {len(data)} reports")
            return True
        else:
            print(f"❌ List reports failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ List reports error: {e}")
        return False

def test_update_report(report_id):
    """Test updating a report."""
    print(f"\nTesting update report {report_id}...")
    
    update_data = {
        "title": "Updated iPhone 13 Pro Max",
        "description": "Updated description with more details about the lost item.",
        "condition": "Excellent",
        "is_urgent": False,
        "reward_amount": "$150",
        "contact_info": "updated@example.com"
    }
    
    try:
        response = requests.patch(f"{BASE_URL}/v1/reports/{report_id}", json=update_data)
        if response.status_code == 200:
            data = response.json()
            print("✅ Report updated successfully")
            print(f"   New title: {data['report']['title']}")
            print(f"   New reward: {data['report']['reward_amount']}")
            return True
        else:
            print(f"❌ Update report failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Update report error: {e}")
        return False

def test_admin_endpoints():
    """Test admin endpoints."""
    print("\nTesting admin endpoints...")
    
    try:
        # Test admin reports list
        response = requests.get(f"{BASE_URL}/v1/admin/reports")
        if response.status_code == 200:
            data = response.json()
            print("✅ Admin reports list working")
            print(f"   Found {data['total']} total reports")
        else:
            print(f"❌ Admin reports list failed: {response.status_code}")
        
        # Test admin stats
        response = requests.get(f"{BASE_URL}/v1/admin/reports/stats")
        if response.status_code == 200:
            data = response.json()
            print("✅ Admin stats working")
            print(f"   Total reports: {data['total']}")
            print(f"   Pending: {data['pending']}")
            print(f"   Approved: {data['approved']}")
        else:
            print(f"❌ Admin stats failed: {response.status_code}")
        
        return True
    except Exception as e:
        print(f"❌ Admin endpoints error: {e}")
        return False

def test_taxonomy_endpoints():
    """Test taxonomy endpoints for categories and colors."""
    print("\nTesting taxonomy endpoints...")
    
    try:
        # Test categories
        response = requests.get(f"{BASE_URL}/v1/taxonomy/categories")
        if response.status_code == 200:
            data = response.json()
            print("✅ Categories endpoint working")
            print(f"   Found {len(data)} categories")
        else:
            print(f"❌ Categories endpoint failed: {response.status_code}")
        
        # Test colors
        response = requests.get(f"{BASE_URL}/v1/taxonomy/colors")
        if response.status_code == 200:
            data = response.json()
            print("✅ Colors endpoint working")
            print(f"   Found {len(data)} colors")
        else:
            print(f"❌ Colors endpoint failed: {response.status_code}")
        
        return True
    except Exception as e:
        print(f"❌ Taxonomy endpoints error: {e}")
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
    lost_report_id = test_create_lost_report()
    if lost_report_id:
        tests_passed += 1
    
    total_tests += 1
    found_report_id = test_create_found_report()
    if found_report_id:
        tests_passed += 1
    
    # Test report retrieval
    if lost_report_id:
        total_tests += 1
        if test_get_report(lost_report_id):
            tests_passed += 1
    
    # Test report listing
    total_tests += 1
    if test_list_reports():
        tests_passed += 1
    
    # Test report update
    if lost_report_id:
        total_tests += 1
        if test_update_report(lost_report_id):
            tests_passed += 1
    
    # Test admin endpoints
    total_tests += 1
    if test_admin_endpoints():
        tests_passed += 1
    
    # Test taxonomy endpoints
    total_tests += 1
    if test_taxonomy_endpoints():
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
