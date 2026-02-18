#!/usr/bin/env bash
#
# Quality Check Script
# Runs all quality checks for the project
#

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $*"; }
log_fail() { echo -e "${RED}[FAIL]${NC} $*"; }

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [LANGUAGE]

Run quality checks for the project.

Languages:
  rust      Check Rust code
  python    Check Python code
  node      Check Node.js code
  all       Check all detected languages (default)

Options:
  --fix       Attempt to fix issues automatically
  --strict    Treat warnings as errors
  -h, --help  Show this help message

EOF
    exit 0
}

FIX=false
STRICT=false
LANGUAGE="all"
FAILED=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --fix)
            FIX=true
            shift
            ;;
        --strict)
            STRICT=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        rust|python|node|all)
            LANGUAGE="$1"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

run_check() {
    local name="$1"
    shift
    local cmd=("$@")

    echo ""
    log_info "Running: $name"

    if "${cmd[@]}"; then
        log_pass "$name"
        return 0
    else
        log_fail "$name"
        ((FAILED++))
        return 1
    fi
}

# Check Rust
check_rust() {
    if [[ ! -f "Cargo.toml" ]]; then
        return 0
    fi

    log_info "Checking Rust project..."

    # Format check
    if [[ "$FIX" == "true" ]]; then
        run_check "cargo fmt" cargo fmt || true
    else
        run_check "cargo fmt --check" cargo fmt -- --check || true
    fi

    # Clippy
    local clippy_args=()
    if [[ "$STRICT" == "true" ]]; then
        clippy_args+=("-D" "warnings")
    fi

    if [[ "$FIX" == "true" ]]; then
        run_check "cargo clippy --fix" cargo clippy --fix --allow-dirty --allow-staged -- "${clippy_args[@]}" || true
    else
        run_check "cargo clippy" cargo clippy -- "${clippy_args[@]}" || true
    fi

    # Build check
    run_check "cargo check" cargo check || true

    # Tests
    run_check "cargo test" cargo test || true

    # Security audit
    if command -v cargo-audit &>/dev/null; then
        run_check "cargo audit" cargo audit || true
    fi
}

# Check Python
check_python() {
    if [[ ! -f "pyproject.toml" ]] && [[ ! -f "setup.py" ]]; then
        return 0
    fi

    log_info "Checking Python project..."

    # Find Python files
    local py_files
    py_files=$(find . -name "*.py" -not -path "./.venv/*" -not -path "./venv/*" -not -path "./.git/*" | head -100)

    if [[ -z "$py_files" ]]; then
        log_warn "No Python files found"
        return 0
    fi

    # Ruff
    if command -v ruff &>/dev/null; then
        if [[ "$FIX" == "true" ]]; then
            run_check "ruff check --fix" ruff check --fix . || true
            run_check "ruff format" ruff format . || true
        else
            run_check "ruff check" ruff check . || true
            run_check "ruff format --check" ruff format --check . || true
        fi
    fi

    # MyPy
    if command -v mypy &>/dev/null; then
        run_check "mypy" mypy . || true
    fi

    # Pytest
    if command -v pytest &>/dev/null; then
        if [[ -d "tests" ]] || find . -name "test_*.py" -quit 2>/dev/null; then
            run_check "pytest" pytest || true
        fi
    fi

    # Security
    if command -v bandit &>/dev/null; then
        run_check "bandit" bandit -r . -x ./.venv,./.git,./venv || true
    fi
}

# Check Node.js
check_node() {
    if [[ ! -f "package.json" ]]; then
        return 0
    fi

    log_info "Checking Node.js project..."

    # Detect package manager
    local pm="npm"
    local pmx="npx"
    if [[ -f "pnpm-lock.yaml" ]]; then
        pm="pnpm"
        pmx="pnpm exec"
    elif [[ -f "yarn.lock" ]]; then
        pm="yarn"
        pmx="yarn"
    fi

    # ESLint
    if [[ -f ".eslintrc.js" ]] || [[ -f ".eslintrc.json" ]] || [[ -f "eslint.config.js" ]]; then
        if [[ "$FIX" == "true" ]]; then
            run_check "eslint --fix" $pmx eslint --fix . || true
        else
            run_check "eslint" $pmx eslint . || true
        fi
    fi

    # Prettier
    if [[ -f ".prettierrc" ]] || [[ -f ".prettierrc.json" ]] || [[ -f "prettier.config.js" ]]; then
        if [[ "$FIX" == "true" ]]; then
            run_check "prettier --write" $pmx prettier --write . || true
        else
            run_check "prettier --check" $pmx prettier --check . || true
        fi
    fi

    # TypeScript
    if [[ -f "tsconfig.json" ]]; then
        run_check "tsc --noEmit" $pmx tsc --noEmit || true
    fi

    # Tests
    if grep -q '"test"' package.json 2>/dev/null; then
        run_check "$pm test" $pm test || true
    fi

    # Audit
    run_check "$pm audit" $pm audit || true
}

# Summary
summary() {
    echo ""
    echo "================================"
    if [[ $FAILED -eq 0 ]]; then
        log_pass "All checks passed!"
    else
        log_fail "$FAILED check(s) failed"
    fi
    echo "================================"
}

# Main
main() {
    case "$LANGUAGE" in
        rust)
            check_rust
            ;;
        python)
            check_python
            ;;
        node)
            check_node
            ;;
        all)
            check_rust
            check_python
            check_node
            ;;
    esac

    summary
    exit $FAILED
}

main
