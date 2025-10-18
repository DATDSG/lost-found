#!/usr/bin/env python3
"""
Seed database script - runs inside the API container
"""
import sys
import os
from datetime import datetime, timedelta
import uuid
import random

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.database import Base
from app.models import (
    User, Report, Media, Match, Conversation, Message, 
    Notification, AuditLog, ReportType, ReportStatus, MatchStatus
)
from app.auth import get_password_hash  # Use the working auth module


def get_database_url():
    """Get database URL from environment."""
    return os.getenv(
        "DATABASE_URL",
        "postgresql+psycopg://postgres:postgres@db:5432/lostfound"
    )


def create_test_users(session, count=10):
    """Create test user accounts."""
    users = []
    
    # Admin user
    admin = User(
        id=uuid.uuid4(),
        email="admin@lostfound.com",
        hashed_password=get_password_hash("Admin123!"),
        display_name="System Admin",
        role="admin",
        is_active=True
    )
    session.add(admin)
    users.append(admin)
    print(f"✅ Created admin user: {admin.email}")
    
    # Regular test users
    first_names = ["John", "Jane", "Alice", "Bob", "Charlie", "Diana", "Eve", "Frank", "Grace", "Henry"]
    last_names = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez"]
    
    for i in range(count):
        user = User(
            id=uuid.uuid4(),
            email=f"user{i+1}@example.com",
            hashed_password=get_password_hash("Test123!"),
            display_name=f"{random.choice(first_names)} {random.choice(last_names)}",
            phone_number=f"+1555{random.randint(1000000, 9999999)}",
            role="user",
            is_active=True
        )
        session.add(user)
        users.append(user)
    
    session.commit()
    print(f"✅ Created {count} test users")
    return users


def create_test_reports(session, users, count=20):
    """Create test lost/found reports."""
    reports = []
    
    items = [
        ("Wallet", "Black leather wallet with multiple cards"),
        ("Phone", "iPhone 14 Pro Max in blue case"),
        ("Keys", "Set of car keys with red keychain"),
        ("Backpack", "Blue Nike backpack with laptop inside"),
        ("Laptop", "MacBook Pro 16-inch with stickers"),
        ("Watch", "Silver Rolex watch"),
        ("Glasses", "Black Ray-Ban sunglasses"),
        ("Umbrella", "Red umbrella with wooden handle"),
        ("Book", "Harry Potter hardcover book"),
        ("Water Bottle", "Blue Hydro Flask water bottle"),
    ]
    
    locations = [
        "Main Campus Library",
        "Student Union Building",
        "Engineering Building",
        "Coffee Shop on 5th Street",
        "City Park near fountain",
        "Downtown Metro Station",
        "Shopping Mall Food Court",
        "University Gym",
        "Public Library",
        "Bus Stop on Main Street",
    ]
    
    for i in range(count):
        item_name, item_desc = random.choice(items)
        report_type = random.choice([ReportType.LOST, ReportType.FOUND])
        
        report = Report(
            id=uuid.uuid4(),
            user_id=random.choice(users).id,
            report_type=report_type,
            item_name=item_name,
            description=item_desc,
            category="Electronics" if "Phone" in item_name or "Laptop" in item_name else "Personal Items",
            location=random.choice(locations),
            latitude=37.7749 + random.uniform(-0.1, 0.1),
            longitude=-122.4194 + random.uniform(-0.1, 0.1),
            lost_found_date=datetime.utcnow() - timedelta(days=random.randint(1, 30)),
            status=random.choice([ReportStatus.OPEN, ReportStatus.CLAIMED, ReportStatus.CLOSED]),
            reward_amount=random.randint(0, 100) if random.random() > 0.5 else None,
        )
        session.add(report)
        reports.append(report)
    
    session.commit()
    print(f"✅ Created {count} test reports")
    return reports


def create_test_matches(session, reports, count=10):
    """Create test matches between reports."""
    matches = []
    
    # Only create matches between LOST and FOUND reports
    lost_reports = [r for r in reports if r.report_type == ReportType.LOST]
    found_reports = [r for r in reports if r.report_type == ReportType.FOUND]
    
    if not lost_reports or not found_reports:
        print("⚠️  Not enough reports to create matches")
        return matches
    
    for _ in range(min(count, len(lost_reports), len(found_reports))):
        lost = random.choice(lost_reports)
        found = random.choice(found_reports)
        
        if lost.id != found.id:
            match = Match(
                id=uuid.uuid4(),
                lost_report_id=lost.id,
                found_report_id=found.id,
                similarity_score=random.uniform(0.7, 0.99),
                text_similarity=random.uniform(0.6, 0.95),
                image_similarity=random.uniform(0.5, 0.9),
                geo_proximity=random.uniform(0.7, 1.0),
                time_proximity=random.uniform(0.6, 0.95),
                status=random.choice([MatchStatus.PENDING, MatchStatus.VERIFIED, MatchStatus.REJECTED]),
            )
            session.add(match)
            matches.append(match)
    
    session.commit()
    print(f"✅ Created {len(matches)} test matches")
    return matches


def main():
    """Main seeding function."""
    print("\n" + "="*60)
    print("Lost & Found Database Seeding")
    print("="*60 + "\n")
    
    # Get database URL
    database_url = get_database_url()
    print(f"📊 Database: {database_url.replace('postgresql+psycopg://', 'postgresql://').split('@')[1]}")
    
    # Create engine and session
    engine = create_engine(database_url)
    SessionLocal = sessionmaker(bind=engine)
    session = SessionLocal()
    
    try:
        print("\nStarting database seeding...\n")
        
        # Create test data
        users = create_test_users(session, count=10)
        reports = create_test_reports(session, users, count=20)
        matches = create_test_matches(session, reports, count=10)
        
        print("\n" + "="*60)
        print("✅ Database seeding completed successfully!")
        print("="*60)
        print(f"\n📊 Summary:")
        print(f"   - Users: {len(users)}")
        print(f"   - Reports: {len(reports)}")
        print(f"   - Matches: {len(matches)}")
        print(f"\n🔑 Admin credentials:")
        print(f"   - Email: admin@lostfound.com")
        print(f"   - Password: Admin123!")
        print(f"\n🔑 Test user credentials:")
        print(f"   - Email: user1@example.com (through user10@example.com)")
        print(f"   - Password: Test123!")
        print()
        
    except Exception as e:
        print(f"\n❌ Error during seeding: {e}")
        session.rollback()
        raise
    finally:
        session.close()


if __name__ == "__main__":
    main()
