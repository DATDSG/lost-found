#!/usr/bin/env python3
"""
Simple and Robust Database Seeding Script using API Endpoints
Seeds the database via HTTP API - the most reliable approach
"""
import requests
import random
from datetime import datetime, timedelta

API_URL = "http://localhost:8000"

def create_users():
    """Create test users via registration API."""
    print("\n📝 Creating Users...")
    users = []
    
    # Test users with realistic names
    test_users_data = [
        ("john.doe@example.com", "John Doe", "Test123!"),
        ("jane.smith@example.com", "Jane Smith", "Test123!"),
        ("alice.wong@example.com", "Alice Wong", "Test123!"),
        ("bob.kumar@example.com", "Bob Kumar", "Test123!"),
        ("carol.fernando@example.com", "Carol Fernando", "Test123!"),
        ("david.silva@example.com", "David Silva", "Test123!"),
        ("emma.perera@example.com", "Emma Perera", "Test123!"),
        ("frank.jones@example.com", "Frank Jones", "Test123!"),
        ("grace.williams@example.com", "Grace Williams", "Test123!"),
        ("henry.lee@example.com", "Henry Lee", "Test123!"),
    ]
    
    for email, name, password in test_users_data:
        try:
            response = requests.post(
                f"{API_URL}/v1/auth/register",
                json={
                    "email": email,
                    "password": password,
                    "display_name": name
                }
            )
            if response.status_code == 200:
                data = response.json()
                users.append({"email": email, "token": data["access_token"], "name": name})
                print(f"  ✅ Created: {email}")
            elif response.status_code == 400:
                # User already exists, try to login
                login_response = requests.post(
                    f"{API_URL}/v1/auth/login",
                    json={"email": email, "password": password}
                )
                if login_response.status_code == 200:
                    data = login_response.json()
                    users.append({"email": email, "token": data["access_token"], "name": name})
                    print(f"  ℹ️  Exists: {email} (logged in)")
                else:
                    print(f"  ⚠️  Skipped: {email} (couldn't login)")
            else:
                print(f"  ❌ Failed: {email} - {response.status_code}")
        except Exception as e:
            print(f"  ❌ Error: {email} - {str(e)}")
    
    return users


def create_reports(users):
    """Create test reports via API."""
    print("\n📦 Creating Reports...")
    reports = []
    
    # Comprehensive item templates for LOST items
    lost_items = [
        ("Lost iPhone 14 Pro", "Lost my black iPhone 14 Pro near the bus station. Has a cracked screen protector and blue case.", "Electronics", ["Black", "Blue"]),
        ("Missing Gold Wedding Ring", "Lost my wedding ring at Galle Face beach. Simple gold band with engraving 'Forever' inside.", "Jewelry", ["Gold"]),
        ("Lost Brown Leather Wallet", "Brown leather wallet with multiple cards, driving license, and some cash. Lost near Majestic City.", "Wallets", ["Brown"]),
        ("Missing Car Keys", "Lost Toyota car keys with blue keychain near Liberty Plaza. Has house keys attached.", "Keys", ["Silver", "Blue"]),
        ("Lost Black Nike Backpack", "Black Nike backpack with laptop inside. Lost at Fort Railway Station. Has name tag.", "Bags", ["Black"]),
        ("Missing Passport", "Sri Lankan passport (red cover) lost at Bandaranaike Airport. Urgent need!", "Documents", ["Red"]),
        ("Lost Pet Cat", "Orange tabby cat named Whiskers. Lost near Viharamahadevi Park. Very friendly.", "Pets", ["Orange"]),
        ("Missing Laptop", "Dell Latitude laptop in black bag. Lost at Coffee Bean Bambalapitiya. Has work stickers.", "Electronics", ["Black", "Silver"]),
        ("Lost Prescription Glasses", "Black frame prescription glasses in blue case. Lost at Odel Colombo 7.", "Other", ["Black", "Blue"]),
        ("Missing Wristwatch", "Silver Casio G-Shock watch with blue dial. Sentimental value. Lost at gym.", "Jewelry", ["Silver", "Blue"]),
        ("Lost Student ID Card", "University of Colombo student ID. Name: Sarah Fernando. Lost in library area.", "Documents", ["Blue", "White"]),
        ("Missing Handbag", "Red leather handbag with phone and makeup inside. Lost in taxi near Crescat.", "Bags", ["Red"]),
        ("Lost Blue Umbrella", "Blue folding umbrella with wooden handle. Left at Nawaloka Hospital.", "Other", ["Blue", "Brown"]),
        ("Missing Headphones", "Black Sony wireless headphones in carrying case. Lost on bus route 138.", "Electronics", ["Black"]),
        ("Lost House Keys", "Set of 5 keys on red keychain. Lost near Keells Super Bambalapitiya.", "Keys", ["Silver", "Red"]),
    ]
    
    # Comprehensive item templates for FOUND items  
    found_items = [
        ("Found iPhone", "Found an iPhone 14 near bus stop. Screen locked but getting calls. Trying to return.", "Electronics", ["Black"]),
        ("Found Gold Ring", "Found a gold ring on Negombo beach this morning. Looks like a wedding band.", "Jewelry", ["Gold"]),
        ("Found Wallet", "Found brown wallet near Majestic City with ID cards. Contact to claim.", "Wallets", ["Brown"]),
        ("Found Car Keys", "Found Toyota keys with blue keychain near Liberty Plaza parking. No contact info.", "Keys", ["Silver", "Blue"]),
        ("Found Backpack", "Found black backpack at railway station. Contains laptop and notebooks.", "Bags", ["Black"]),
        ("Found Passport", "Found Sri Lankan passport near airport departure hall. Will hand to lost & found.", "Documents", ["Red"]),
        ("Found Cat", "Found friendly orange cat near park. Well-fed, seems to be someone's pet.", "Pets", ["Orange"]),
        ("Found Laptop Bag", "Found black laptop bag in taxi. Contains Dell laptop and charger.", "Electronics", ["Black"]),
        ("Found Glasses", "Found prescription glasses in blue case near Odel. In good condition.", "Other", ["Black", "Blue"]),
        ("Found Watch", "Found silver watch near gym locker room. Casio brand with blue face.", "Jewelry", ["Silver", "Blue"]),
        ("Found Student ID", "Found University of Colombo student ID. Will keep at security office.", "Documents", ["Blue", "White"]),
        ("Found Handbag", "Found red leather handbag in taxi. Contains phone and personal items.", "Bags", ["Red"]),
        ("Found Umbrella", "Found blue umbrella at hospital reception. Nice wooden handle.", "Other", ["Blue"]),
        ("Found Headphones", "Found Sony wireless headphones on bus. In black carrying case.", "Electronics", ["Black"]),
        ("Found Keys", "Found set of house keys on red keychain near Keells. 5 keys total.", "Keys", ["Silver", "Red"]),
    ]
    
    cities = [
        'Colombo', 'Kandy', 'Galle', 'Jaffna', 'Negombo',
        'Matara', 'Kurunegala', 'Anuradhapura', 'Batticaloa'
    ]
    
    addresses = [
        "256 Galle Road, Colombo 03",
        "145 Kandy Road, Colombo 07",
        "89 Duplication Road, Colombo 04",
        "432 Union Place, Colombo 02",
        "67 Baseline Road, Colombo 09",
    ]
    
    # Create 30 reports (15 LOST + 15 FOUND)
    for i in range(30):
        if not users:
            break
        
        user = random.choice(users)
        is_lost = i % 2 == 0
        templates = lost_items if is_lost else found_items
        
        title, description, category, colors = random.choice(templates)
        title = f"{title} - #{i+1:03d}"
        
        days_ago = random.randint(1, 60)
        occurred_at = (datetime.utcnow() - timedelta(days=days_ago)).isoformat()
        
        try:
            response = requests.post(
                f"{API_URL}/v1/reports",
                headers={"Authorization": f"Bearer {user['token']}"},
                json={
                    "type": "lost" if is_lost else "found",  # lowercase
                    "title": title,
                    "description": description,
                    "category": category,
                    "colors": colors,
                    "occurred_at": occurred_at,
                    "location_city": random.choice(cities),
                    "location_address": random.choice(addresses),
                    "reward_offered": random.choice([True, False]) if is_lost else False
                }
            )
            
            if response.status_code in [200, 201]:
                print(f"  ✅ {i+1}/30: {title[:50]}...")
                reports.append(response.json())
            else:
                print(f"  ❌ {i+1}/30: Failed - {response.status_code}")
                if response.status_code != 401:  # Don't print details for auth errors
                    try:
                        print(f"       {response.json()}")
                    except:
                        pass
        except Exception as e:
            print(f"  ❌ {i+1}/30: Error - {str(e)}")
    
    return reports


def main():
    """Main seeding function."""
    print("\n" + "="*70)
    print(" 🌱 SIMPLE DATABASE SEEDING VIA API")
    print("="*70)
    
    try:
        # Check API health
        response = requests.get(f"{API_URL}/health")
        if response.status_code != 200:
            print("\n❌ API is not responding. Please check if the service is running.")
            return
        
        print(f"\n✅ API is healthy at {API_URL}")
        
        # Create test data
        users = create_users()
        print(f"\n✅ Total users available: {len(users)}")
        
        if users:
            reports = create_reports(users)
            print(f"\n✅ Total reports created: {len(reports)}")
        else:
            print("\n⚠️  No users available to create reports")
            return
        
        print("\n" + "="*70)
        print(" ✅ DATABASE SEEDING COMPLETED!")
        print("="*70)
        
        print(f"\n📊 SUMMARY:")
        print(f"   👥 Users:   {len(users)}")
        print(f"   📝 Reports: {len(reports)}")
        
        print(f"\n🔑 TEST CREDENTIALS:")
        print(f"   Email:    admin@lostfound.com OR any test user")
        print(f"   Password: Admin123! OR Test123!")
        
        print(f"\n🌐 NEXT STEPS:")
        print(f"   1. Login to http://localhost:3000 (admin app)")
        print(f"   2. Test CRUD operations on reports")
        print(f"   3. Check that all data is properly displayed")
        
        print("\n" + "="*70 + "\n")
        
    except Exception as e:
        print(f"\n❌ ERROR: {str(e)}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
