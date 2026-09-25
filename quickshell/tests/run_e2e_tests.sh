#!/run/current-system/sw/bin/bash
# ==============================================================================
# Quickshell E2E Master Test Runner
# Executes opaque-box test suites across Tiers 1-4 and Static Quality.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
export PYTHONPATH="${REPO_ROOT}:${PYTHONPATH:-}"

# Terminal color output
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    BOLD="\033[1m"
    GREEN="\033[1;32m"
    RED="\033[1;31m"
    YELLOW="\033[1;33m"
    BLUE="\033[1;34m"
    CYAN="\033[1;36m"
    RESET="\033[0m"
else
    BOLD=""
    GREEN=""
    RED=""
    YELLOW=""
    BLUE=""
    CYAN=""
    RESET=""
fi

TARGET_TIER=""
TARGET_MILESTONE=""
TARGET_FILE=""
VERBOSE=0

print_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
  --tier <1|2|3|4|static>   Run only specified tier
  --milestone <M1|M2|M3|M4> Run tests covering specific milestone
  --file <path>             Run a specific test script
  -v, --verbose             Verbose test runner output
  -h, --help                Show this help message

Examples:
  $0                        # Run full E2E test suite
  $0 --tier 1               # Run Tier 1 Feature Coverage
  $0 --milestone M1         # Run Milestone 1 tests
  $0 --tier static          # Run static quality & log checks
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --tier)
            TARGET_TIER="$2"
            shift 2
            ;;
        --milestone)
            TARGET_MILESTONE="$2"
            shift 2
            ;;
        --file)
            TARGET_FILE="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            print_usage
            exit 1
            ;;
    esac
done

echo -e "${BOLD}${CYAN}======================================================${RESET}"
echo -e "${BOLD}${CYAN}  Quickshell Desktop Environment E2E Test Suite       ${RESET}"
echo -e "${BOLD}${CYAN}======================================================${RESET}"
echo -e "Repo Root: ${REPO_ROOT}"
export REPO_ROOT
export TARGET_TIER
export TARGET_MILESTONE
export TARGET_FILE
export VERBOSE

# Python test runner script that discovers and executes tests with structured reporting
python3 - << 'PYEOF'
import sys
import os
import unittest
import time
from pathlib import Path

repo_root = Path(os.environ["REPO_ROOT"])
tests_dir = repo_root / "tests"

target_tier = os.environ.get("TARGET_TIER", "").strip().lower()
target_ms = os.environ.get("TARGET_MILESTONE", "").strip().upper()
target_file = os.environ.get("TARGET_FILE", "").strip()
verbose = int(os.environ.get("VERBOSE", "0"))

suites_to_run = []

# Map milestones to test files
m1_files = [f"test_f0{i}_" for i in range(1, 8)]
m2_files = [f"test_f0{i}_" if i < 10 else f"test_f{i}_" for i in range(8, 13)]
m3_files = [f"test_f{i}_" for i in range(13, 19)]
m4_files = [f"test_f{i}_" for i in range(19, 23)]

tier_dirs = {
    "1": ("Tier 1 (Feature Coverage)", tests_dir / "tier1_features"),
    "2": ("Tier 2 (Boundary & Stress)", tests_dir / "tier2_boundary"),
    "3": ("Tier 3 (Cross-Feature Pairwise)", tests_dir / "tier3_pairwise"),
    "4": ("Tier 4 (Real-World Workloads)", tests_dir / "tier4_workflows"),
    "static": ("Static Quality & Log Audit", tests_dir / "static_quality")
}

if target_file:
    fpath = Path(target_file)
    if not fpath.is_absolute():
        fpath = repo_root / fpath
    loader = unittest.TestLoader()
    suite = loader.discover(str(fpath.parent), pattern=fpath.name)
    suites_to_run.append((f"File: {fpath.name}", suite))
else:
    for tier_key, (tier_name, tier_path) in tier_dirs.items():
        if target_tier and target_tier != tier_key:
            continue
        if not tier_path.exists():
            continue
        
        loader = unittest.TestLoader()
        if target_ms:
            # Filter files by milestone
            patterns = []
            if target_ms == "M1": patterns = m1_files
            elif target_ms == "M2": patterns = m2_files
            elif target_ms == "M3": patterns = m3_files
            elif target_ms == "M4": patterns = m4_files
            
            combined_suite = unittest.TestSuite()
            for py_file in sorted(tier_path.glob("test_*.py")):
                if any(p in py_file.name for p in patterns):
                    suite = loader.discover(str(tier_path), pattern=py_file.name)
                    combined_suite.addTests(suite)
            suites_to_run.append((f"{tier_name} [{target_ms}]", combined_suite))
        else:
            suite = loader.discover(str(tier_path), pattern="test_*.py")
            suites_to_run.append((tier_name, suite))

total_ran = 0
total_passed = 0
total_failed = 0
total_errors = 0
total_skipped = 0
start_time = time.time()

print(f"{'SUITE':<35} | {'RUN':<5} | {'PASS':<5} | {'FAIL':<5} | {'ERR':<5} | {'SKIP':<5} | {'STATUS'}")
print("-" * 80)

overall_success = True

for name, suite in suites_to_run:
    test_count = suite.countTestCases()
    if test_count == 0:
        continue
    runner = unittest.TextTestRunner(verbosity=2 if verbose else 0, stream=open(os.devnull, 'w'))
    result = runner.run(suite)
    
    ran = result.testsRun
    failed = len(result.failures)
    errors = len(result.errors)
    skipped = len(result.skipped)
    passed = ran - failed - errors - skipped
    
    total_ran += ran
    total_passed += passed
    total_failed += failed
    total_errors += errors
    total_skipped += skipped
    
    is_ok = (failed == 0 and errors == 0)
    if not is_ok:
        overall_success = False
    
    status_str = "\033[1;32mPASS\033[0m" if is_ok else "\033[1;31mFAIL\033[0m"
    print(f"{name:<35} | {ran:<5} | {passed:<5} | {failed:<5} | {errors:<5} | {skipped:<5} | {status_str}")
    
    if (failed > 0 or errors > 0) and verbose:
        for f, tb in result.failures + result.errors:
            print(f"\n  [!] {f}")
            for line in tb.splitlines()[-3:]:
                print(f"      {line}")

duration = time.time() - start_time
print("-" * 80)
summary_status = "\033[1;32mALL TESTS PASSED\033[0m" if overall_success else "\033[1;31mFAILURES DETECTED\033[0m"
print(f"TOTAL: {total_ran} tests run in {duration:.2f}s | Passed: {total_passed} | Failed: {total_failed} | Errors: {total_errors} | Skipped: {total_skipped}")
print(f"OVERALL RESULT: {summary_status}")
print("=" * 80)

sys.exit(0 if overall_success else 1)
PYEOF
