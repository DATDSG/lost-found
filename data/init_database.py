"""
Database initialization script for Lost & Found Platform
Handles creating extensions, running migrations, and seeding data
"""
import os
import sys
import subprocess
from pathlib import Path


def run_command(cmd, cwd=None):
    """Run a shell command and return the result."""
    print(f"\n▶ Running: {cmd}")
    result = subprocess.run(
        cmd, 
        shell=True, 
        cwd=cwd,
        capture_output=True,
        text=True
    )
    
    if result.stdout:
        print(result.stdout)
    if result.stderr:
        print(result.stderr)
    
    if result.returncode != 0:
        print(f"❌ Command failed with exit code {result.returncode}")
        return False
    
    print("✓ Command completed successfully")
    return True


def check_database_connection():
    """Check if database is accessible."""
    print("\n" + "="*60)
    print("Checking Database Connection")
    print("="*60)

    db_url = os.getenv("DATABASE_URL", "postgresql+psycopg://postgres:postgres@host.docker.internal:5432/lostfound")
    print(f"Database URL: {db_url.split('@')[1] if '@' in db_url else 'Not set'}")
    
    # Simple check using psql
    check_cmd = 'docker-compose exec -T db pg_isready -U lostfound'
    if not run_command(check_cmd):
        print("\n⚠️  Database not ready. Make sure PostgreSQL is running.")
        print("   Try: docker-compose up -d db")
        return False
    
    return True


def run_migrations():
    """Run Alembic migrations."""
    print("\n" + "="*60)
    print("Running Database Migrations")
    print("="*60)
    
    # Change to API directory
    api_dir = Path(__file__).parent.parent / "services" / "api"
    
    # Run migrations
    if not run_command("alembic upgrade head", cwd=api_dir):
        print("\n❌ Migrations failed!")
        return False
    
    print("\n✓ All migrations completed successfully")
    return True


def seed_database():
    """Seed the database with initial data."""
    print("\n" + "="*60)
    print("Seeding Database")
    print("="*60)
    
    seed_script = Path(__file__).parent / "seed" / "seed_database.py"
    
    if not seed_script.exists():
        print(f"⚠️  Seed script not found: {seed_script}")
        return False
    
    # Run seed script
    if not run_command(f"python {seed_script}"):
        print("\n❌ Database seeding failed!")
        return False
    
    print("\n✓ Database seeded successfully")
    return True


def show_migration_status():
    """Show current migration status."""
    print("\n" + "="*60)
    print("Migration Status")
    print("="*60)
    
    api_dir = Path(__file__).parent.parent / "services" / "api"
    run_command("alembic current", cwd=api_dir)
    run_command("alembic history", cwd=api_dir)


def main():
    """Main initialization function."""
    print("\n" + "="*70)
    print(" Lost & Found Platform - Database Initialization")
    print("="*70)
    
    # Check if database is accessible
    if not check_database_connection():
        print("\n❌ Database connection check failed. Aborting.")
        sys.exit(1)
    
    # Run migrations
    if not run_migrations():
        print("\n❌ Migration process failed. Aborting.")
        sys.exit(1)
    
    # Ask if user wants to seed
    print("\n" + "-"*60)
    seed_choice = input("Do you want to seed the database with test data? (y/N): ").strip().lower()
    
    if seed_choice == 'y':
        if not seed_database():
            print("\n⚠️  Seeding failed, but migrations were successful.")
    else:
        print("Skipping database seeding.")
    
    # Show final status
    show_migration_status()
    
    print("\n" + "="*70)
    print(" Database initialization completed!")
    print("="*70)
    print("\nNext steps:")
    print("  1. Start the API server: cd services/api && uvicorn app.main:app --reload")
    print("  2. Access API docs: http://localhost:8000/docs")
    print("  3. Test login with: admin@lostfound.com / Admin123!")
    print("\n")


if __name__ == "__main__":
    main()
