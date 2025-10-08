#!/usr/bin/env python
"""
Management script for Lost & Found API services.

Usage:
    python manage.py start              # Start all services
    python manage.py stop               # Stop all services
    python manage.py restart            # Restart all services
    python manage.py status             # Check service status
    python manage.py logs [service]     # View logs
    python manage.py build              # Build Docker images
    python manage.py migrate            # Run database migrations
    python manage.py test               # Run test suite
    python manage.py shell              # Open Python shell with app context
"""

import sys
import subprocess
import argparse
from pathlib import Path


COMPOSE_DIR = Path(__file__).parent.parent.parent / "infra" / "compose"
API_DIR = Path(__file__).parent


def run_compose_command(args: list[str], description: str = None):
    """Run docker-compose command."""
    if description:
        print(f"\n🔄 {description}...")
    
    cmd = ["docker-compose"] + args
    result = subprocess.run(cmd, cwd=COMPOSE_DIR)
    
    if result.returncode == 0 and description:
        print(f"✅ {description} - Complete")
    elif result.returncode != 0:
        print(f"❌ Command failed with exit code {result.returncode}")
    
    return result.returncode


def start_services(args):
    """Start all services."""
    print("\n" + "="*80)
    print("🚀 Starting Lost & Found Services")
    print("="*80)
    
    compose_args = ["up", "-d"]
    if args.build:
        compose_args.append("--build")
    
    return run_compose_command(compose_args, "Starting services")


def stop_services(args):
    """Stop all services."""
    print("\n" + "="*80)
    print("🛑 Stopping Lost & Found Services")
    print("="*80)
    
    return run_compose_command(["down"], "Stopping services")


def restart_services(args):
    """Restart all services."""
    print("\n" + "="*80)
    print("🔄 Restarting Lost & Found Services")
    print("="*80)
    
    stop_services(args)
    return start_services(args)


def status_services(args):
    """Check service status."""
    print("\n" + "="*80)
    print("📊 Service Status")
    print("="*80 + "\n")
    
    return run_compose_command(["ps"])


def view_logs(args):
    """View service logs."""
    print("\n" + "="*80)
    print(f"📋 Viewing Logs{' for ' + args.service if args.service else ''}")
    print("="*80 + "\n")
    
    compose_args = ["logs"]
    if args.follow:
        compose_args.append("-f")
    if args.tail:
        compose_args.extend(["--tail", str(args.tail)])
    if args.service:
        compose_args.append(args.service)
    
    return run_compose_command(compose_args)


def build_images(args):
    """Build Docker images."""
    print("\n" + "="*80)
    print("🔨 Building Docker Images")
    print("="*80)
    
    compose_args = ["build"]
    if args.no_cache:
        compose_args.append("--no-cache")
    if args.service:
        compose_args.append(args.service)
    
    return run_compose_command(compose_args, "Building images")


def run_migrations(args):
    """Run database migrations."""
    print("\n" + "="*80)
    print("🗃️  Running Database Migrations")
    print("="*80 + "\n")
    
    cmd = ["docker-compose", "exec", "api", "alembic", "upgrade", "head"]
    result = subprocess.run(cmd, cwd=COMPOSE_DIR)
    
    if result.returncode == 0:
        print("\n✅ Migrations applied successfully")
    else:
        print("\n❌ Migration failed")
    
    return result.returncode


def run_tests(args):
    """Run test suite."""
    print("\n" + "="*80)
    print("🧪 Running Test Suite")
    print("="*80 + "\n")
    
    cmd = [sys.executable, "run_tests.py"]
    
    if args.coverage:
        cmd.append("--coverage")
    if args.verbose:
        cmd.append("--verbose")
    if args.unit:
        cmd.append("--unit")
    if args.integration:
        cmd.append("--integration")
    if args.performance:
        cmd.append("--performance")
    
    result = subprocess.run(cmd, cwd=API_DIR)
    return result.returncode


def open_shell(args):
    """Open Python shell with app context."""
    print("\n" + "="*80)
    print("🐍 Opening Python Shell")
    print("="*80 + "\n")
    
    cmd = ["docker-compose", "exec", "api", "python", "-i", "-c",
           "from app.main import app; from app.database import SessionLocal; "
           "from app.models import *; "
           "db = SessionLocal(); "
           "print('App context loaded. Available: app, db, User, Report, etc.')"]
    
    return subprocess.run(cmd, cwd=COMPOSE_DIR).returncode


def check_health(args):
    """Check health of all services."""
    print("\n" + "="*80)
    print("🏥 Checking Service Health")
    print("="*80 + "\n")
    
    services = [
        ("API", "http://localhost:8000/health"),
        ("Prometheus", "http://localhost:9090/-/healthy"),
        ("Grafana", "http://localhost:3000/api/health"),
    ]
    
    try:
        import requests
        
        for name, url in services:
            try:
                response = requests.get(url, timeout=5)
                if response.status_code == 200:
                    print(f"✅ {name}: Healthy")
                else:
                    print(f"⚠️  {name}: Unhealthy (status {response.status_code})")
            except Exception as e:
                print(f"❌ {name}: Unreachable ({str(e)})")
    
    except ImportError:
        print("⚠️  'requests' library not installed. Install with: pip install requests")
        return 1
    
    return 0


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Lost & Found API Management Script",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python manage.py start                 Start all services
  python manage.py start --build         Start and rebuild images
  python manage.py logs api -f           Follow API logs
  python manage.py logs --tail 100       Show last 100 log lines
  python manage.py test --coverage       Run tests with coverage
  python manage.py migrate               Run database migrations
        """
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Command to execute')
    
    # Start command
    start_parser = subparsers.add_parser('start', help='Start all services')
    start_parser.add_argument('--build', action='store_true', help='Build images before starting')
    start_parser.set_defaults(func=start_services)
    
    # Stop command
    stop_parser = subparsers.add_parser('stop', help='Stop all services')
    stop_parser.set_defaults(func=stop_services)
    
    # Restart command
    restart_parser = subparsers.add_parser('restart', help='Restart all services')
    restart_parser.add_argument('--build', action='store_true', help='Build images before restarting')
    restart_parser.set_defaults(func=restart_services)
    
    # Status command
    status_parser = subparsers.add_parser('status', help='Check service status')
    status_parser.set_defaults(func=status_services)
    
    # Logs command
    logs_parser = subparsers.add_parser('logs', help='View service logs')
    logs_parser.add_argument('service', nargs='?', help='Service name (optional)')
    logs_parser.add_argument('-f', '--follow', action='store_true', help='Follow log output')
    logs_parser.add_argument('--tail', type=int, help='Number of lines to show')
    logs_parser.set_defaults(func=view_logs)
    
    # Build command
    build_parser = subparsers.add_parser('build', help='Build Docker images')
    build_parser.add_argument('service', nargs='?', help='Service name (optional)')
    build_parser.add_argument('--no-cache', action='store_true', help='Build without cache')
    build_parser.set_defaults(func=build_images)
    
    # Migrate command
    migrate_parser = subparsers.add_parser('migrate', help='Run database migrations')
    migrate_parser.set_defaults(func=run_migrations)
    
    # Test command
    test_parser = subparsers.add_parser('test', help='Run test suite')
    test_parser.add_argument('--coverage', action='store_true', help='Generate coverage report')
    test_parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    test_parser.add_argument('--unit', action='store_true', help='Unit tests only')
    test_parser.add_argument('--integration', action='store_true', help='Integration tests only')
    test_parser.add_argument('--performance', action='store_true', help='Performance tests only')
    test_parser.set_defaults(func=run_tests)
    
    # Shell command
    shell_parser = subparsers.add_parser('shell', help='Open Python shell with app context')
    shell_parser.set_defaults(func=open_shell)
    
    # Health command
    health_parser = subparsers.add_parser('health', help='Check health of all services')
    health_parser.set_defaults(func=check_health)
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return 1
    
    return args.func(args)


if __name__ == '__main__':
    sys.exit(main())
