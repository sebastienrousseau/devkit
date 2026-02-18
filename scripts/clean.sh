#!/usr/bin/env bash
#
# Clean Build Artifacts Script
# Removes build artifacts, caches, and temporary files
#

set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Clean build artifacts and caches.

Options:
  -a, --all       Clean everything (including node_modules, .venv)
  -d, --dry-run   Show what would be deleted
  -h, --help      Show this help message

EOF
    exit 0
}

DRY_RUN=false
CLEAN_ALL=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--all)
            CLEAN_ALL=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            shift
            ;;
    esac
done

remove() {
    local path="$1"
    if [[ -e "$path" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY RUN] Would remove: $path"
        else
            rm -rf "$path"
            log_info "Removed: $path"
        fi
    fi
}

# Clean Rust artifacts
clean_rust() {
    if [[ -f "Cargo.toml" ]]; then
        log_info "Cleaning Rust artifacts..."
        remove "target"

        # Clean cargo cache if --all
        if [[ "$CLEAN_ALL" == "true" ]]; then
            if command -v cargo-cache &>/dev/null; then
                if [[ "$DRY_RUN" != "true" ]]; then
                    cargo cache -a
                fi
            fi
        fi
    fi
}

# Clean Python artifacts
clean_python() {
    if [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || [[ -f "requirements.txt" ]]; then
        log_info "Cleaning Python artifacts..."

        # __pycache__ directories
        find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

        # .pyc files
        find . -type f -name "*.pyc" -delete 2>/dev/null || true

        # .pyo files
        find . -type f -name "*.pyo" -delete 2>/dev/null || true

        # Build directories
        remove "build"
        remove "dist"
        remove "*.egg-info"
        remove ".eggs"

        # Test/coverage
        remove ".pytest_cache"
        remove ".coverage"
        remove "htmlcov"
        remove ".mypy_cache"
        remove ".ruff_cache"

        # Virtual environment
        if [[ "$CLEAN_ALL" == "true" ]]; then
            remove ".venv"
            remove "venv"
        fi
    fi
}

# Clean Node.js artifacts
clean_node() {
    if [[ -f "package.json" ]]; then
        log_info "Cleaning Node.js artifacts..."

        remove "dist"
        remove "build"
        remove ".next"
        remove ".nuxt"
        remove ".output"
        remove ".cache"
        remove ".parcel-cache"
        remove ".turbo"

        # Coverage
        remove "coverage"

        # Dependencies
        if [[ "$CLEAN_ALL" == "true" ]]; then
            remove "node_modules"
        fi
    fi
}

# Clean general artifacts
clean_general() {
    log_info "Cleaning general artifacts..."

    # Editor/IDE
    remove ".idea"
    remove "*.swp"
    remove "*~"

    # OS
    remove ".DS_Store"
    remove "Thumbs.db"

    # Logs
    find . -type f -name "*.log" -delete 2>/dev/null || true

    # Temp files
    remove "tmp"
    remove ".tmp"
    remove "temp"
}

# Main
main() {
    log_info "Starting cleanup..."

    clean_rust
    clean_python
    clean_node
    clean_general

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "Dry run complete. No files were deleted."
    else
        log_info "Cleanup complete!"
    fi
}

main
