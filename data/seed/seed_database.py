"""
Seed data script for Lost & Found database
Populates initial test data for development and testing
"""
import sys
import os
from datetime import datetime, timedelta
from uuid import uuid4
import random
from pathlib import Path

# Add API directory to path (fixed: correct path to services/api)
api_dir = Path(__file__).parent.parent.parent / "services" / "api"
sys.path.insert(0, str(api_dir))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from passlib.context import CryptContext

from app.database import Base, get_db
from app.models import (
    User, Report, Media, Match, Conversation, Message, 
    Notification, AuditLog, ReportType, ReportStatus, MatchStatus
)

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def get_database_url():
    """Get database URL from environment or use default."""
    return os.getenv(
        "DATABASE_URL",
        "postgresql+psycopg://postgres:postgres@host.docker.internal:5432/lostfound"
    )


def create_test_users(session, count=10):
    """Create test user accounts."""
    users = []
    
    # Admin user
    admin = User(
        id=str(uuid4()),
        email="admin@lostfound.com",
        hashed_password=pwd_context.hash("Admin123!"),
        display_name="System Admin",
        role="admin",
        is_active=True
    )
    session.add(admin)
    users.append(admin)
    
    # Regular test users
    test_users_data = [
        ("john.doe@example.com", "John Doe"),
        ("jane.smith@example.com", "Jane Smith"),
        ("alice.wong@example.com", "Alice Wong"),
        ("bob.kumar@example.com", "Bob Kumar"),
        ("carol.fernando@example.com", "Carol Fernando"),
        ("david.silva@example.com", "David Silva"),
        ("emma.perera@example.com", "Emma Perera"),
        ("frank.jones@example.com", "Frank Jones"),
        ("grace.williams@example.com", "Grace Williams"),
    ]
    
    for email, name in test_users_data[:count-1]:
        user = User(
            id=str(uuid4()),
            email=email,
            hashed_password=pwd_context.hash("Test123!"),
            display_name=name,
            role="user",
            is_active=True
        )
        session.add(user)
        users.append(user)
    
    session.commit()
    print(f"✓ Created {len(users)} test users")
    return users


def create_test_reports(session, users, count=30):
    """Create test lost and found reports."""
    reports = []
    
    categories = [
        'electronics', 'accessories', 'jewelry', 'documents', 'keys',
        'wallets', 'clothing', 'pets', 'books', 'other'
    ]
    
    colors_list = [
        ['black'], ['white'], ['gray'], ['silver'], ['red'], 
        ['blue'], ['green'], ['brown'], ['black', 'white'],
        ['blue', 'gray'], ['red', 'black'], ['multicolor']
    ]
    
    cities = [
        'Colombo', 'Kandy', 'Galle', 'Jaffna', 'Negombo',
        'Matara', 'Kurunegala', 'Anuradhapura', 'Batticaloa', 'Trincomalee'
    ]
    
    # Sample report templates
    lost_items = [
        ("Lost iPhone 13 Pro", "Lost my black iPhone 13 Pro near the main bus station. Has a crack on the screen.", "electronics", ["black"]),
        ("Missing Gold Ring", "Lost my wedding ring at the beach. It's a simple gold band with engraving inside.", "jewelry", ["gold"]),
        ("Lost Wallet", "Brown leather wallet with ID cards and credit cards. Lost near shopping mall.", "wallets", ["brown"]),
        ("Missing Keys", "Car keys with Toyota key fob and house keys on a blue keychain.", "keys", ["silver", "blue"]),
        ("Lost Backpack", "Black Nike backpack with laptop inside. Lost at the train station.", "accessories", ["black"]),
        ("Missing Pet Dog", "Small brown terrier dog named Max. Lost near park area.", "pets", ["brown"]),
        ("Lost Passport", "Sri Lankan passport in red cover. Lost at airport area.", "documents", ["red"]),
        ("Missing Laptop", "Dell laptop in black bag. Has company stickers on it.", "electronics", ["black", "silver"]),
        ("Lost Glasses", "Black frame prescription glasses in blue case.", "accessories", ["black"]),
        ("Missing Watch", "Silver Casio watch with blue dial.", "accessories", ["silver", "blue"]),
    ]
    
    found_items = [
        ("Found iPhone", "Found an iPhone near the park. Screen is locked.", "electronics", ["black"]),
        ("Found Ring", "Found a gold ring on the beach. Looks valuable.", "jewelry", ["gold"]),
        ("Found Wallet", "Found brown wallet with some cash and cards.", "wallets", ["brown"]),
        ("Found Keys", "Found car keys near parking lot. Toyota brand.", "keys", ["silver"]),
        ("Found Bag", "Found black backpack at train station. Contains laptop.", "accessories", ["black"]),
        ("Found Dog", "Found small dog wandering near park. Very friendly.", "pets", ["brown"]),
        ("Found Document", "Found passport near airport terminal.", "documents", ["red"]),
        ("Found Laptop Bag", "Found laptop bag in taxi. Contains Dell laptop.", "electronics", ["black"]),
        ("Found Eyewear", "Found glasses in blue case near library.", "accessories", ["black", "blue"]),
        ("Found Wristwatch", "Found silver watch near gym.", "accessories", ["silver"]),
    ]
    
    # Create mix of lost and found reports
    for i in range(count):
        user = random.choice(users)
        is_lost = i % 2 == 0
        templates = lost_items if is_lost else found_items
        
        title, description, category, colors = random.choice(templates)
        
        # Add some variation to titles
        title = f"{title} #{i+1}"
        
        occurred_at = datetime.utcnow() - timedelta(days=random.randint(1, 90))
        
        report = Report(
            id=str(uuid4()),
            owner_id=user.id,
            type=ReportType.LOST if is_lost else ReportType.FOUND,
            status=random.choice([ReportStatus.PENDING, ReportStatus.APPROVED, ReportStatus.APPROVED]),
            title=title,
            description=description,
            category=category,
            colors=colors,
            occurred_at=occurred_at,
            location_city=random.choice(cities),
            location_address=f"{random.randint(1, 500)} Main Street"
        )
        
        session.add(report)
        reports.append(report)
    
    session.commit()
    print(f"✓ Created {len(reports)} test reports")
    return reports


def create_test_notifications(session, users, count=20):
    """Create test notifications."""
    notifications = []
    
    notification_types = [
        ("new_match", "New Match Found!", "We found a potential match for your report."),
        ("new_message", "New Message", "You have a new message in your conversation."),
        ("report_approved", "Report Approved", "Your report has been approved and is now visible."),
        ("status_update", "Status Update", "There's an update on one of your reports."),
    ]
    
    for _ in range(count):
        user = random.choice(users)
        ntype, title, content = random.choice(notification_types)
        
        notification = Notification(
            id=str(uuid4()),
            user_id=user.id,
            type=ntype,
            title=title,
            content=content,
            is_read=random.choice([True, False, False])  # 1/3 chance of being read
        )
        
        session.add(notification)
        notifications.append(notification)
    
    session.commit()
    print(f"✓ Created {len(notifications)} test notifications")
    return notifications


def create_audit_log_entries(session, users, count=50):
    """Create audit log entries."""
    logs = []
    
    actions = [
        ("report.create", "reports"),
        ("report.update", "reports"),
        ("report.approve", "reports"),
        ("report.hide", "reports"),
        ("user.login", "users"),
        ("user.update", "users"),
        ("match.create", "matches"),
        ("match.dismiss", "matches"),
    ]
    
    for _ in range(count):
        user = random.choice(users) if random.random() > 0.1 else None  # 10% system actions
        action, resource = random.choice(actions)
        
        log = AuditLog(
            id=str(uuid4()),
            user_id=user.id if user else None,
            action=action,
            resource_type=resource,
            resource_id=str(uuid4()),
            details=f"Automated test action: {action}"
        )
        
        session.add(log)
        logs.append(log)
    
    session.commit()
    print(f"✓ Created {len(logs)} audit log entries")
    return logs


def main():
    """Main seed function."""
    print("\n" + "="*60)
    print("Lost & Found Database Seeding")
    print("="*60 + "\n")
    
    # Create engine and session
    engine = create_engine(get_database_url())
    SessionLocal = sessionmaker(bind=engine)
    session = SessionLocal()
    
    try:
        print("Starting database seeding...\n")
        
        # Create test data
        users = create_test_users(session, count=10)
        reports = create_test_reports(session, users, count=30)
        notifications = create_test_notifications(session, users, count=20)
        audit_logs = create_audit_log_entries(session, users, count=50)
        
        print("\n" + "="*60)
        print("Seeding completed successfully!")
        print("="*60)
        print("\nTest Credentials:")
        print("  Admin: admin@lostfound.com / Admin123!")
        print("  Users: john.doe@example.com / Test123!")
        print("         (and other test users)")
        print("\n")
        
    except Exception as e:
        print(f"\n❌ Error during seeding: {str(e)}")
        session.rollback()
        raise
    finally:
        session.close()


if __name__ == "__main__":
    main()
