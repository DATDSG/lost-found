"""Validation script to verify restructured backend health.

Run this after restructuring to ensure all services are properly configured.
"""
import sys
from pathlib import Path

# Add project root to path for imports
root = Path(__file__).parent.parent
if str(root) not in sys.path:
    sys.path.insert(0, str(root))

# Colors for output
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
RESET = '\033[0m'

def check(name: str, fn) -> bool:
    """Run a check and print result."""
    try:
        result = fn()
        if result:
            print(f"{GREEN}✓{RESET} {name}")
            return True
        else:
            print(f"{RED}✗{RESET} {name}")
            return False
    except Exception as e:
        print(f"{RED}✗{RESET} {name}: {e}")
        return False


def main():
    """Run all validation checks."""
    root = Path(__file__).parent.parent
    checks_passed = 0
    checks_total = 0
    
    print("\n🔍 Backend Restructure Validation\n")
    
    # Structure checks
    print("📁 Directory Structure:")
    checks_total += 1
    checks_passed += check(
        "backend/common/ exists",
        lambda: (root / "backend" / "common").exists()
    )
    
    checks_total += 1
    checks_passed += check(
        "backend/common/health.py exists",
        lambda: (root / "backend" / "common" / "health.py").exists()
    )
    
    checks_total += 1
    checks_passed += check(
        "research/ directory exists",
        lambda: (root / "research").exists()
    )
    
    checks_total += 1
    checks_passed += check(
        "research/notebooks/ exists",
        lambda: (root / "research" / "notebooks").exists()
    )
    
    checks_total += 1
    checks_passed += check(
        "research/legacy_src/ exists (archived src)",
        lambda: (root / "research" / "legacy_src").exists()
    )
    
    checks_total += 1
    checks_passed += check(
        "backend/api/src/ removed",
        lambda: not (root / "backend" / "api" / "src").exists()
    )
    
    checks_total += 1
    checks_passed += check(
        "backend/nlp/notebooks/ removed",
        lambda: not (root / "backend" / "nlp" / "notebooks").exists()
    )
    
    checks_total += 1
    checks_passed += check(
        "backend/vision/notebooks/ removed",
        lambda: not (root / "backend" / "vision" / "notebooks").exists()
    )
    
    # File checks
    print("\n📄 Configuration Files:")
    checks_total += 1
    checks_passed += check(
        "pyproject.toml exists",
        lambda: (root / "pyproject.toml").exists()
    )
    
    checks_total += 1
    checks_passed += check(
        "tests/test_health_endpoints.py exists",
        lambda: (root / "tests" / "test_health_endpoints.py").exists()
    )
    
    dockerignore_files = [
        "backend/api/.dockerignore",
        "backend/nlp/.dockerignore",
        "backend/vision/.dockerignore",
        "backend/worker/.dockerignore",
    ]
    for file in dockerignore_files:
        checks_total += 1
        checks_passed += check(
            f"{file} exists",
            lambda f=file: (root / f).exists()
        )
    
    # Import checks
    print("\n🐍 Python Imports:")
    
    checks_total += 1
    checks_passed += check(
        "backend.common.health imports",
        lambda: __import__("backend.common.health")
    )
    
    checks_total += 1
    checks_passed += check(
        "backend.common.health.readiness available",
        lambda: hasattr(__import__("backend.common.health", fromlist=["readiness"]), "readiness")
    )
    
    checks_total += 1
    checks_passed += check(
        "backend.common.models.soft_delete imports",
        lambda: __import__("backend.common.models.soft_delete")
    )
    
    # Test execution
    print("\n🧪 Tests:")
    import subprocess
    result = subprocess.run(
        [sys.executable, "-m", "pytest", "tests/test_health_endpoints.py::test_common_health_registry", "-v"],
        cwd=root,
        capture_output=True,
        text=True
    )
    checks_total += 1
    if result.returncode == 0:
        checks_passed += 1
        print(f"{GREEN}✓{RESET} test_common_health_registry passes")
    else:
        print(f"{RED}✗{RESET} test_common_health_registry fails")
        print(result.stdout)
        print(result.stderr)
    
    # Summary
    print("\n" + "="*50)
    percentage = (checks_passed / checks_total * 100) if checks_total > 0 else 0
    if checks_passed == checks_total:
        print(f"{GREEN}✓ All checks passed!{RESET} ({checks_passed}/{checks_total})")
    else:
        print(f"{YELLOW}⚠ {checks_passed}/{checks_total} checks passed ({percentage:.1f}%){RESET}")
    
    return checks_passed == checks_total


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
