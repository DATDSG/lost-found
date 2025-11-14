"""Tests for admin bulk operations endpoints."""
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from uuid import uuid4

from app.main import app
from app.models import User
from app.domains.reports.models.report import Report, ReportStatus, ReportType
from app.domains.matches.models.match import Match, MatchStatus
from app.infrastructure.database.session import get_async_db


@pytest.fixture
def admin_user(db: Session):
    """Create an admin user for testing."""
    user = User(
        id=str(uuid4()),
        email="admin@test.com",
        hashed_password="hashed_password",
        display_name="Admin User",
        role="admin",
        is_active=True
    )
    db.add(user)
    db.commit()
    return user


@pytest.fixture
def regular_user(db: Session):
    """Create a regular user for testing."""
    user = User(
        id=str(uuid4()),
        email="user@test.com",
        hashed_password="hashed_password",
        display_name="Regular User",
        role="user",
        is_active=True
    )
    db.add(user)
    db.commit()
    return user


@pytest.fixture
def test_reports(db: Session, regular_user: User):
    """Create test reports."""
    reports = []
    for i in range(5):
        report = Report(
            id=str(uuid4()),
            owner_id=regular_user.id,
            type=ReportType.LOST,
            status=ReportStatus.PENDING,
            title=f"Test Report {i}",
            description=f"Test description {i}",
            category="electronics",
            location_city="Test City"
        )
        db.add(report)
        reports.append(report)
    db.commit()
    return reports


@pytest.fixture
def test_matches(db: Session, test_reports):
    """Create test matches."""
    matches = []
    for i in range(3):
        match = Match(
            id=str(uuid4()),
            source_report_id=test_reports[i].id,
            target_report_id=test_reports[i+1].id,
            status=MatchStatus.CANDIDATE,
            score_total=0.85
        )
        db.add(match)
        matches.append(match)
    db.commit()
    return matches


# ============================================================================
# REPORTS BULK OPERATIONS TESTS
# ============================================================================

def test_bulk_approve_reports_success(client: TestClient, admin_user: User, test_reports):
    """Test successful bulk approval of reports."""
    report_ids = [report.id for report in test_reports[:3]]
    
    response = client.post(
        "/admin/reports/bulk/approve",
        json={"ids": report_ids},
        headers={"Authorization": f"Bearer {admin_user.id}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] == 3
    assert data["failed"] == 0
    assert len(data["errors"]) == 0


def test_bulk_approve_reports_partial_failure(client: TestClient, admin_user: User, test_reports):
    """Test bulk approval with some non-existent IDs."""
    report_ids = [test_reports[0].id, "non-existent-id", test_reports[1].id]
    
    response = client.post(
        "/admin/reports/bulk/approve",
        json={"ids": report_ids},
        headers={"Authorization": f"Bearer {admin_user.id}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] == 2
    assert data["failed"] == 1
    assert len(data["errors"]) == 1
    assert data["errors"][0]["id"] == "non-existent-id"


def test_bulk_reject_reports_success(client: TestClient, admin_user: User, test_reports):
    """Test successful bulk rejection of reports."""
    report_ids = [report.id for report in test_reports[:2]]
    
    response = client.post(
        "/admin/reports/bulk/reject",
        json={"ids": report_ids},
        headers={"Authorization": f"Bearer {admin_user.id}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] == 2
    assert data["failed"] == 0


def test_bulk_delete_reports_success(client: TestClient, admin_user: User, test_reports):
    """Test successful bulk deletion of reports."""
    report_ids = [report.id for report in test_reports[:2]]
    
    response = client.post(
        "/admin/reports/bulk/delete",
        json={"ids": report_ids},
        headers={"Authorization": f"Bearer {admin_user.id}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] == 2
    assert data["failed"] == 0


def test_bulk_operations_empty_list(client: TestClient, admin_user: User):
    """Test bulk operation with empty ID list."""
    response = client.post(
        "/admin/reports/bulk/approve",
        json={"ids": []},
        headers={"Authorization": f"Bearer {admin_user.id}"}
    )
    
    assert response.status_code == 422  # Validation error


def test_bulk_operations_too_many_ids(client: TestClient, admin_user: User):
    """Test bulk operation with too many IDs (>100)."""
    report_ids = [str(uuid4()) for _ in range(101)]
    
    response = client.post(
        "/admin/reports/bulk/approve",
        json={"ids": report_ids},
        headers={"Authorization": f"Bearer {admin_user.id}"}
    )
    
    assert response.status_code == 422  # Validation error


# ============================================================================
# USERS BULK OPERATIONS TESTS
# ============================================================================

def test_bulk_activate_users_success(client: TestClient, admin_user: User, db: Session):
    """Test successful bulk activation of users."""
    # Create inactive users
    users = []
    for i in range(3):
        user = User(
            id=str(uuid4()),
            email=f"inactive{i}@test.com",
            hashed_password="hashed",
            is_active=False
        )
        db.add(user)
        users.append(user)
    db.commit()
    
    user_ids = [user.id for user in users]
    
    response = client.post(
        "/admin/users/bulk/activate",
        json={"ids": user_ids},
        headers={"Authorization": f"Bearer {admin_user.id}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] == 3
    assert data["failed"] == 0


def test_bulk_deactivate_users_cannot_modify_self(client: TestClient, admin_user: User):
    """Test that admin cannot deactivate themselves."""
    response = client.post(
        "/admin/users/bulk/deactivate",
        json={"ids": [admin_user.id]},
        headers={"Authorization": f"Bearer {admin_user.id}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] == 0
    assert data["failed"] == 1
    assert "Cannot modify your own account" in data["errors"][0]["error"]


def test_bulk_delete_users_success(client: TestClient, admin_user: User, db: Session):
    """Test successful bulk deletion (soft delete) of users."""
    # Create users to delete
    users = []
    for i in range(2):
        user = User(
            id=str(uuid4()),
            email=f"deleteme{i}@test.com",
            hashed_password="hashed",
            is_active=True
        )
        db.add(user)
        users.append(user)
    db.commit()
    
    user_ids = [user.id for user in users]
    
    response = client.post(
        "/admin/users/bulk/delete",
        json={"ids": user_ids},
        headers={"Authorization": f"Bearer {admin_user.id}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] == 2
    assert data["failed"] == 0


# ============================================================================
# MATCHES BULK OPERATIONS TESTS
# ============================================================================

def test_bulk_approve_matches_success(client: TestClient, admin_user: User, test_matches):
    """Test successful bulk approval of matches."""
    match_ids = [match.id for match in test_matches[:2]]
    
    response = client.post(
        "/admin/matches/bulk/approve",
        json={"ids": match_ids},
        headers={"Authorization": f"Bearer {admin_user.id}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] == 2
    assert data["failed"] == 0


def test_bulk_reject_matches_success(client: TestClient, admin_user: User, test_matches):
    """Test successful bulk rejection of matches."""
    match_ids = [match.id for match in test_matches[:2]]
    
    response = client.post(
        "/admin/matches/bulk/reject",
        json={"ids": match_ids},
        headers={"Authorization": f"Bearer {admin_user.id}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["success"] == 2
    assert data["failed"] == 0


# ============================================================================
# AUTHORIZATION TESTS
# ============================================================================

def test_bulk_operations_require_admin(client: TestClient, regular_user: User, test_reports):
    """Test that bulk operations require admin role."""
    report_ids = [test_reports[0].id]
    
    response = client.post(
        "/admin/reports/bulk/approve",
        json={"ids": report_ids},
        headers={"Authorization": f"Bearer {regular_user.id}"}
    )
    
    assert response.status_code == 403  # Forbidden


def test_bulk_operations_require_authentication(client: TestClient, test_reports):
    """Test that bulk operations require authentication."""
    report_ids = [test_reports[0].id]
    
    response = client.post(
        "/admin/reports/bulk/approve",
        json={"ids": report_ids}
    )
    
    assert response.status_code == 401  # Unauthorized
