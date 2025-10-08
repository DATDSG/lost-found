#!/usr/bin/env python
"""
Comprehensive test runner for the Lost & Found API.

Usage:
    python run_tests.py                    # Run all tests
    python run_tests.py --unit             # Unit tests only
    python run_tests.py --integration      # Integration tests only
    python run_tests.py --performance      # Performance tests only
    python run_tests.py --load             # Load tests only
    python run_tests.py --coverage         # With coverage report
    python run_tests.py --verbose          # Verbose output
"""

import sys
import subprocess
import argparse
from pathlib import Path


def run_command(cmd: list[str], description: str) -> int:
    """Run a command and return the exit code."""
    print(f"\n{'='*80}")
    print(f"🔄 {description}")
    print(f"{'='*80}\n")
    
    result = subprocess.run(cmd, cwd=Path(__file__).parent)
    
    if result.returncode == 0:
        print(f"\n✅ {description} - PASSED")
    else:
        print(f"\n❌ {description} - FAILED")
    
    return result.returncode


def main():
    """Main test runner."""
    parser = argparse.ArgumentParser(description="Run Lost & Found API tests")
    parser.add_argument('--unit', action='store_true', help='Run unit tests only')
    parser.add_argument('--integration', action='store_true', help='Run integration tests only')
    parser.add_argument('--performance', action='store_true', help='Run performance tests only')
    parser.add_argument('--load', action='store_true', help='Run load tests only')
    parser.add_argument('--coverage', action='store_true', help='Generate coverage report')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    parser.add_argument('--markers', '-m', help='Run tests with specific markers')
    
    args = parser.parse_args()
    
    # Base pytest command
    base_cmd = ['pytest']
    
    # Add verbosity
    if args.verbose:
        base_cmd.append('-v')
    else:
        base_cmd.append('-q')
    
    # Add coverage if requested
    if args.coverage:
        base_cmd.extend([
            '--cov=app',
            '--cov-report=html',
            '--cov-report=term-missing',
            '--cov-report=xml'
        ])
    
    exit_codes = []
    
    # Determine which tests to run
    if args.unit:
        cmd = base_cmd + ['tests/test_matching.py', '-m', 'not slow']
        exit_codes.append(run_command(cmd, "Unit Tests"))
    
    elif args.integration:
        cmd = base_cmd + ['tests/test_clients.py']
        exit_codes.append(run_command(cmd, "Integration Tests"))
    
    elif args.performance:
        cmd = base_cmd + ['tests/test_performance.py', '-m', 'performance']
        exit_codes.append(run_command(cmd, "Performance Tests"))
    
    elif args.load:
        cmd = base_cmd + ['tests/test_performance.py', '-m', 'load', '-s']
        exit_codes.append(run_command(cmd, "Load Tests"))
    
    elif args.markers:
        cmd = base_cmd + ['-m', args.markers]
        exit_codes.append(run_command(cmd, f"Tests with marker: {args.markers}"))
    
    else:
        # Run all test suites
        print("\n" + "="*80)
        print("🚀 Running Complete Test Suite")
        print("="*80)
        
        # Unit tests
        cmd = base_cmd + ['tests/test_matching.py', '-m', 'not slow']
        exit_codes.append(run_command(cmd, "Unit Tests"))
        
        # Integration tests
        cmd = base_cmd + ['tests/test_clients.py']
        exit_codes.append(run_command(cmd, "Integration Tests"))
        
        # Performance tests
        cmd = base_cmd + ['tests/test_performance.py', '-m', 'performance and not slow']
        exit_codes.append(run_command(cmd, "Performance Tests (Quick)"))
    
    # Print summary
    print("\n" + "="*80)
    print("📊 TEST SUMMARY")
    print("="*80)
    
    total_tests = len(exit_codes)
    passed_tests = sum(1 for code in exit_codes if code == 0)
    failed_tests = total_tests - passed_tests
    
    print(f"\nTotal test suites: {total_tests}")
    print(f"Passed: {passed_tests} ✅")
    print(f"Failed: {failed_tests} ❌")
    
    if args.coverage:
        print("\n📈 Coverage report generated:")
        print("   - HTML: htmlcov/index.html")
        print("   - XML: coverage.xml")
        print("\nTo view HTML report:")
        print("   open htmlcov/index.html  # macOS/Linux")
        print("   start htmlcov/index.html  # Windows")
    
    print("\n" + "="*80)
    
    # Return non-zero exit code if any tests failed
    return 0 if failed_tests == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
