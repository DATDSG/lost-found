#!/usr/bin/env python3
"""
Comprehensive Database Seeding Script
Seeds the database with realistic test data for frontend CRUD testing
"""
import sys
import os
from datetime import datetime, timedelta
from uuid import uuid4
import random

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

from app.database import Base
from app.models import (
    User, Report, Media, Match, Conversation, Message, 
    Notification, AuditLog, ReportType, ReportStatus, MatchStatus
)
from app.auth import get_password_hash


def get_database_url():
    """Get database URL from environment."""
    return os.getenv(
        "DATABASE_URL",
        "postgresql+psycopg://postgres:postgres@db:5432/lostfound"
    )


def create_test_users(session, count=15):
    """Create test user accounts with realistic data."""
    users = []
    
    # Admin user (skip if exists)
    try:
        existing_admin = session.query(User).filter(User.email == "admin@lostfound.com").first()
        if existing_admin:
            print("ℹ️  Admin user already exists, skipping...")
            users.append(existing_admin)
        else:
            admin = User(
                email="admin@lostfound.com",
                hashed_password=get_password_hash("Admin123!"),
                display_name="System Admin",
                role="admin",
                is_active=True
            )
            session.add(admin)
            session.flush()
            users.append(admin)
            print(f"✅ Created admin user: {admin.email}")
    except Exception as e:
        print(f"⚠️  Error creating admin: {e}")
        session.rollback()
        session.begin()
    
    # Test users with realistic names and data
    test_users_data = [
        ("john.doe@example.com", "John Doe", "+94771234567"),
        ("jane.smith@example.com", "Jane Smith", "+94772345678"),
        ("alice.wong@example.com", "Alice Wong", "+94773456789"),
        ("bob.kumar@example.com", "Bob Kumar", "+94774567890"),
        ("carol.fernando@example.com", "Carol Fernando", "+94775678901"),
        ("david.silva@example.com", "David Silva", "+94776789012"),
        ("emma.perera@example.com", "Emma Perera", "+94777890123"),
        ("frank.jones@example.com", "Frank Jones", "+94778901234"),
        ("grace.williams@example.com", "Grace Williams", "+94779012345"),
        ("henry.lee@example.com", "Henry Lee", "+94770123456"),
        ("isabel.garcia@example.com", "Isabel Garcia", "+94771234560"),
        ("jack.brown@example.com", "Jack Brown", "+94772345601"),
        ("kelly.davis@example.com", "Kelly Davis", "+94773456012"),
        ("liam.martinez@example.com", "Liam Martinez", "+94774560123"),
    ]
    
    for i, (email, name, phone) in enumerate(test_users_data[:count-1]):
        try:
            existing_user = session.query(User).filter(User.email == email).first()
            if existing_user:
                users.append(existing_user)
                continue
                
            user = User(
                email=email,
                hashed_password=get_password_hash("Test123!"),
                display_name=name,
                phone_number=phone,
                role="user",
                is_active=True
            )
            session.add(user)
            session.flush()
            users.append(user)
        except Exception as e:
            print(f"⚠️  Error creating user {email}: {e}")
            continue
    
    session.commit()
    print(f"✅ Total users available: {len(users)}")
    return users


def create_test_reports(session, users, count=40):
    """Create diverse lost and found reports for comprehensive CRUD testing."""
    reports = []
    
    # Categories matching the frontend
    categories = [
        'Electronics', 'Jewelry', 'Documents', 'Keys', 
        'Wallets', 'Clothing', 'Pets', 'Books', 'Bags', 'Other'
    ]
    
    # Color options
    colors_options = [
        ['Black'], ['White'], ['Gray'], ['Silver'], ['Red'], 
        ['Blue'], ['Green'], ['Brown'], ['Yellow'], ['Pink'],
        ['Black', 'White'], ['Blue', 'Gray'], ['Red', 'Black'], ['Multicolor']
    ]
    
    # Cities in Sri Lanka
    cities = [
        'Colombo', 'Kandy', 'Galle', 'Jaffna', 'Negombo',
        'Matara', 'Kurunegala', 'Anuradhapura', 'Batticaloa', 'Trincomalee',
        'Ratnapura', 'Badulla', 'Nuwara Eliya', 'Ampara', 'Kalutara'
    ]
    
    # Comprehensive item templates for LOST items
    lost_items = [
        ("Lost iPhone 14 Pro", "Lost my black iPhone 14 Pro near the bus station. Has a cracked screen protector and blue case.", "Electronics", ["Black", "Blue"]),
        ("Missing Gold Wedding Ring", "Lost my wedding ring at Galle Face beach. Simple gold band with engraving 'Forever' inside.", "Jewelry", ["Gold"]),
        ("Lost Brown Leather Wallet", "Brown leather wallet with multiple cards, driving license, and some cash. Lost near Majestic City.", "Wallets", ["Brown"]),
        ("Missing Car Keys", "Lost Toyota car keys with blue keychain near Liberty Plaza. Has house keys attached.", "Keys", ["Silver", "Blue"]),
        ("Lost Black Nike Backpack", "Black Nike backpack with laptop inside. Lost at Fort Railway Station. Has name tag 'John'.", "Bags", ["Black"]),
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
        ("Missing Dog - Max", "Small brown terrier named Max. Lost near Independence Square. Wearing red collar.", "Pets", ["Brown"]),
        ("Lost Camera", "Canon EOS M50 camera with black strap. Lost at Lotus Tower. In black camera bag.", "Electronics", ["Black"]),
        ("Missing Jacket", "Navy blue North Face jacket. Left at Cinnamon Gardens. Has initials 'RK' inside.", "Clothing", ["Blue"]),
        ("Lost Textbook", "Medical textbook - Gray's Anatomy. Lost at Medical Faculty canteen. Name inside.", "Books", ["Blue"]),
        ("Missing Sunglasses", "Ray-Ban aviator sunglasses in brown case. Lost at Mount Lavinia beach.", "Other", ["Silver", "Brown"]),
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
        ("Found Dog", "Found small brown dog wandering near Independence Square. Wearing collar.", "Pets", ["Brown"]),
        ("Found Camera", "Found Canon camera in black bag at Lotus Tower. Looks expensive.", "Electronics", ["Black"]),
        ("Found Jacket", "Found navy blue jacket at park. North Face brand with initials inside.", "Clothing", ["Blue"]),
        ("Found Medical Book", "Found Gray's Anatomy textbook at canteen. Has student name inside.", "Books", ["Blue"]),
        ("Found Sunglasses", "Found Ray-Ban sunglasses in brown case at beach. Good condition.", "Other", ["Silver", "Brown"]),
    ]
    
    # Locations/addresses
    addresses = [
        "256 Galle Road, Colombo 03",
        "145 Kandy Road, Colombo 07",
        "89 Duplication Road, Colombo 04",
        "432 Union Place, Colombo 02",
        "67 Baseline Road, Colombo 09",
        "321 Parliament Road, Battaramulla",
        "178 High Level Road, Nugegoda",
        "234 Nawala Road, Rajagiriya",
        "91 Station Road, Colombo 06",
        "156 Marine Drive, Colombo 03",
    ]
    
    # Colombo coordinates (center)
    base_lat = 6.9271
    base_lon = 79.8612
    
    # Create balanced mix of LOST and FOUND reports
    for i in range(count):
        user = random.choice(users)
        is_lost = i % 2 == 0
        templates = lost_items if is_lost else found_items
        
        title, description, category, colors = random.choice(templates)
        
        # Add variation to titles
        title = f"{title} - #{i+1:03d}"
        
        # Random date within last 90 days
        days_ago = random.randint(1, 90)
        occurred_at = datetime.utcnow() - timedelta(days=days_ago)
        
        # Random location near Colombo (we'll set geo separately)
        lat = base_lat + random.uniform(-0.1, 0.1)
        lon = base_lon + random.uniform(-0.1, 0.1)
        geo_wkt = f'SRID=4326;POINT({lon} {lat})'
        
        # Status distribution: mostly APPROVED for testing
        status_weights = [ReportStatus.PENDING, ReportStatus.APPROVED, ReportStatus.APPROVED, ReportStatus.APPROVED]
        
        report = Report(
            id=str(uuid4()),  # Explicitly set ID
            owner_id=str(user.id),
            type=ReportType.LOST if is_lost else ReportType.FOUND,
            status=random.choice(status_weights),
            title=title,
            description=description,
            category=category,
            colors=colors,
            occurred_at=occurred_at,
            # geo=None,  # Skip geo during INSERT, set it with UPDATE
            location_city=random.choice(cities),
            location_address=random.choice(addresses),
            reward_offered=random.choice([True, False]) if is_lost else False,
            is_resolved=random.choice([False, False, False, True])  # 25% resolved
        )
        
        # Add report without geo first
        session.add(report)
        reports.append(report)
    
    # Commit all reports first
    session.commit()
    
    # Now update geo fields using raw SQL
    print(f"  Setting geographic coordinates...")
    for report in reports:
        lat = base_lat + random.uniform(-0.1, 0.1)
        lon = base_lon + random.uniform(-0.1, 0.1)
        geo_wkt = f'SRID=4326;POINT({lon} {lat})'
        try:
            session.execute(
                text("UPDATE reports SET geo = ST_GeomFromEWKT(:geom) WHERE id = :id"),
                {"geom": geo_wkt, "id": report.id}
            )
        except:
            pass  # Skip if PostGIS not available
    
    session.commit()
    print(f"✅ Created {len(reports)} test reports ({count//2} LOST, {count//2} FOUND)")
    return reports


def create_test_matches(session, reports, count=15):
    """Create realistic matches between LOST and FOUND reports."""
    matches = []
    
    # Separate LOST and FOUND reports
    lost_reports = [r for r in reports if r.type == ReportType.LOST]
    found_reports = [r for r in reports if r.type == ReportType.FOUND]
    
    if not lost_reports or not found_reports:
        print("⚠️  Not enough reports to create matches")
        return matches
    
    # Create matches with varying similarity scores
    for i in range(min(count, len(lost_reports), len(found_reports))):
        lost = random.choice(lost_reports)
        found = random.choice(found_reports)
        
        # Avoid duplicate matches
        existing_match = session.query(Match).filter(
            Match.source_report_id == str(lost.id),
            Match.candidate_report_id == str(found.id)
        ).first()
        
        if existing_match:
            continue
        
        # Generate realistic similarity scores
        base_score = random.uniform(0.65, 0.95)
        
        match = Match(
            id=str(uuid4()),  # Explicitly set ID
            source_report_id=str(lost.id),
            candidate_report_id=str(found.id),
            similarity_score=base_score,
            text_similarity=base_score + random.uniform(-0.1, 0.1),
            image_similarity=base_score + random.uniform(-0.15, 0.05),
            location_proximity=random.uniform(0.5, 1.0),
            time_proximity=random.uniform(0.6, 0.95),
            status=random.choice([MatchStatus.PENDING, MatchStatus.PENDING, MatchStatus.VERIFIED, MatchStatus.DISMISSED])
        )
        
        session.add(match)
        session.flush()
        matches.append(match)
    
    session.commit()
    print(f"✅ Created {len(matches)} test matches")
    return matches


def create_test_notifications(session, users, count=25):
    """Create test notifications for user testing."""
    notifications = []
    
    notification_templates = [
        ("new_match", "New Match Found!", "We found a potential match for your lost item report."),
        ("new_match", "Possible Match", "Someone found an item that matches your description."),
        ("new_message", "New Message", "You have a new message about your report."),
        ("new_message", "Reply Received", "Someone replied to your message."),
        ("report_approved", "Report Approved", "Your report has been reviewed and approved."),
        ("report_approved", "Now Visible", "Your report is now visible to other users."),
        ("status_update", "Report Updated", "Your report status has been updated."),
        ("status_update", "Item Resolved", "Your report has been marked as resolved."),
    ]
    
    for _ in range(count):
        user = random.choice(users)
        ntype, title, content = random.choice(notification_templates)
        
        notification = Notification(
            id=str(uuid4()),  # Explicitly set ID
            user_id=str(user.id),
            type=ntype,
            title=title,
            content=content,
            is_read=random.choice([True, False, False, False])  # 25% read
        )
        
        session.add(notification)
        notifications.append(notification)
    
    session.commit()
    print(f"✅ Created {len(notifications)} test notifications")
    return notifications


def create_audit_logs(session, users, count=30):
    """Create audit log entries for system tracking."""
    logs = []
    
    actions = [
        ("report.create", "reports", "Created new report"),
        ("report.update", "reports", "Updated report details"),
        ("report.approve", "reports", "Approved report for publishing"),
        ("report.resolve", "reports", "Marked report as resolved"),
        ("user.login", "users", "User logged in"),
        ("user.update", "users", "Updated profile information"),
        ("match.create", "matches", "System generated match"),
        ("match.verify", "matches", "User verified match"),
        ("match.dismiss", "matches", "User dismissed match"),
    ]
    
    for _ in range(count):
        user = random.choice(users) if random.random() > 0.2 else None  # 20% system actions
        action, resource, detail = random.choice(actions)
        
        log = AuditLog(
            id=str(uuid4()),  # Explicitly set ID
            user_id=str(user.id) if user else None,
            action=action,
            resource_type=resource,
            resource_id=str(uuid4()),
            details=detail,
            ip_address=f"192.168.1.{random.randint(1, 254)}",
            user_agent="Mozilla/5.0 (Test)"
        )
        
        session.add(log)
        logs.append(log)
    
    session.commit()
    print(f"✅ Created {len(logs)} audit log entries")
    return logs


def main():
    """Main seeding function with comprehensive data."""
    print("\n" + "="*70)
    print(" 🌱 COMPREHENSIVE DATABASE SEEDING FOR FRONTEND CRUD TESTING")
    print("="*70 + "\n")
    
    # Get database URL
    database_url = get_database_url()
    db_info = database_url.split('@')[1] if '@' in database_url else 'localhost'
    print(f"📊 Database: {db_info}")
    print(f"🕐 Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    
    # Create engine and session
    engine = create_engine(database_url, echo=False)
    SessionLocal = sessionmaker(bind=engine)
    session = SessionLocal()
    
    try:
        print("🚀 Starting comprehensive database seeding...\n")
        print("-" * 70)
        
        # Create test data with realistic volumes
        users = create_test_users(session, count=15)
        reports = create_test_reports(session, users, count=40)
        matches = create_test_matches(session, reports, count=15)
        notifications = create_test_notifications(session, users, count=25)
        audit_logs = create_audit_logs(session, users, count=30)
        
        print("\n" + "-" * 70)
        print("\n" + "="*70)
        print(" ✅ DATABASE SEEDING COMPLETED SUCCESSFULLY!")
        print("="*70)
        
        print(f"\n📊 SUMMARY:")
        print(f"   👥 Users:         {len(users):>3} (1 admin + {len(users)-1} regular users)")
        print(f"   📝 Reports:       {len(reports):>3} ({len([r for r in reports if r.type == ReportType.LOST])} LOST + {len([r for r in reports if r.type == ReportType.FOUND])} FOUND)")
        print(f"   🔗 Matches:       {len(matches):>3}")
        print(f"   🔔 Notifications: {len(notifications):>3}")
        print(f"   📋 Audit Logs:    {len(audit_logs):>3}")
        
        print(f"\n🔑 TEST CREDENTIALS:")
        print(f"\n   👑 Admin Access:")
        print(f"      Email:    admin@lostfound.com")
        print(f"      Password: Admin123!")
        
        print(f"\n   👤 Regular Users:")
        print(f"      Email:    john.doe@example.com (or other test users)")
        print(f"      Password: Test123!")
        
        print(f"\n📍 QUICK STATS:")
        approved_reports = len([r for r in reports if r.status == ReportStatus.APPROVED])
        pending_reports = len([r for r in reports if r.status == ReportStatus.PENDING])
        resolved_reports = len([r for r in reports if r.is_resolved])
        
        print(f"   Approved Reports:  {approved_reports}")
        print(f"   Pending Reports:   {pending_reports}")
        print(f"   Resolved Reports:  {resolved_reports}")
        
        print(f"\n🌐 FRONTEND TESTING:")
        print(f"   ✓ CRUD operations ready for all entities")
        print(f"   ✓ Realistic data with proper relationships")
        print(f"   ✓ Various statuses for testing workflows")
        print(f"   ✓ Geographic data for map features")
        
        print(f"\n🕐 Completed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("="*70 + "\n")
        
    except Exception as e:
        print(f"\n❌ ERROR DURING SEEDING:")
        print(f"   {str(e)}")
        import traceback
        traceback.print_exc()
        session.rollback()
        raise
    finally:
        session.close()


if __name__ == "__main__":
    main()
