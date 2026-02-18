#!/usr/bin/env bash
#
# Update Dependencies Script
# Updates dependencies across different language ecosystems
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

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [LANGUAGE]

Update dependencies for the current project.

Languages:
  rust      Update Cargo dependencies
  python    Update Python dependencies
  node      Update Node.js dependencies
  all       Update all detected languages (default)

Options:
  -c, --check     Check for updates without applying
  -m, --minor     Only update minor/patch versions
  -a, --audit     Run security audit after update
  -h, --help      Show this help message

Examples:
  $(basename "$0")              # Update all
  $(basename "$0") rust         # Update Rust only
  $(basename "$0") --check      # Check for updates
  $(basename "$0") --audit all  # Update and audit
EOF
    exit 0
}

# Parse arguments
CHECK_ONLY=false
MINOR_ONLY=false
RUN_AUDIT=false
LANGUAGE="all"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--check)
            CHECK_ONLY=true
            shift
            ;;
        -m|--minor)
            MINOR_ONLY=true
            shift
            ;;
        -a|--audit)
            RUN_AUDIT=true
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
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Update Rust dependencies
update_rust() {
    if [[ ! -f "Cargo.toml" ]]; then
        return 0
    fi

    log_info "Updating Rust dependencies..."

    if [[ "$CHECK_ONLY" == "true" ]]; then
        if command -v cargo-outdated &>/dev/null; then
            cargo outdated
        else
            log_warn "cargo-outdated not installed. Run: cargo install cargo-outdated"
            cargo update --dry-run
        fi
    else
        cargo update
        log_info "Rust dependencies updated"
    fi

    if [[ "$RUN_AUDIT" == "true" ]]; then
        if command -v cargo-audit &>/dev/null; then
            log_info "Running cargo audit..."
            cargo audit
        else
            log_warn "cargo-audit not installed. Run: cargo install cargo-audit"
        fi
    fi
}

# Update Python dependencies
update_python() {
    if [[ ! -f "pyproject.toml" ]] && [[ ! -f "requirements.txt" ]]; then
        return 0
    fi

    log_info "Updating Python dependencies..."

    if [[ -f "pyproject.toml" ]]; then
        if command -v poetry &>/dev/null && grep -q "tool.poetry" pyproject.toml; then
            if [[ "$CHECK_ONLY" == "true" ]]; then
                poetry show --outdated
            else
                poetry update
                log_info "Python dependencies updated (poetry)"
            fi
        elif command -v uv &>/dev/null; then
            if [[ "$CHECK_ONLY" == "true" ]]; then
                uv pip list --outdated
            else
                uv pip compile pyproject.toml -o requirements.lock
                log_info "Python dependencies updated (uv)"
            fi
        elif command -v pip &>/dev/null; then
            if [[ "$CHECK_ONLY" == "true" ]]; then
                pip list --outdated
            else
                pip install -e ".[dev]" --upgrade
                log_info "Python dependencies updated (pip)"
            fi
        fi
    elif [[ -f "requirements.txt" ]]; then
        if [[ "$CHECK_ONLY" == "true" ]]; then
            pip list --outdated
        else
            pip install -r requirements.txt --upgrade
            log_info "Python dependencies updated"
        fi
    fi

    if [[ "$RUN_AUDIT" == "true" ]]; then
        if command -v pip-audit &>/dev/null; then
            log_info "Running pip-audit..."
            pip-audit
        elif command -v safety &>/dev/null; then
            log_info "Running safety check..."
            safety check
        else
            log_warn "pip-audit/safety not installed"
        fi
    fi
}

# Update Node.js dependencies
update_node() {
    if [[ ! -f "package.json" ]]; then
        return 0
    fi

    log_info "Updating Node.js dependencies..."

    # Detect package manager
    local pm="npm"
    if [[ -f "pnpm-lock.yaml" ]]; then
        pm="pnpm"
    elif [[ -f "yarn.lock" ]]; then
        pm="yarn"
    fi

    if [[ "$CHECK_ONLY" == "true" ]]; then
        case "$pm" in
            pnpm)
                pnpm outdated
                ;;
            yarn)
                yarn outdated
                ;;
            *)
                npm outdated
                ;;
        esac
    else
        case "$pm" in
            pnpm)
                if [[ "$MINOR_ONLY" == "true" ]]; then
                    pnpm update
                else
                    pnpm update --latest
                fi
                ;;
            yarn)
                if [[ "$MINOR_ONLY" == "true" ]]; then
                    yarn upgrade
                else
                    yarn upgrade --latest
                fi
                ;;
            *)
                if [[ "$MINOR_ONLY" == "true" ]]; then
                    npm update
                else
                    npm update --save
                fi
                ;;
        esac
        log_info "Node.js dependencies updated ($pm)"
    fi

    if [[ "$RUN_AUDIT" == "true" ]]; then
        log_info "Running npm audit..."
        case "$pm" in
            pnpm)
                pnpm audit
                ;;
            yarn)
                yarn audit
                ;;
            *)
                npm audit
                ;;
        esac
    fi
}

# Main
main() {
    case "$LANGUAGE" in
        rust)
            update_rust
            ;;
        python)
            update_python
            ;;
        node)
            update_node
            ;;
        all)
            update_rust
            update_python
            update_node
            ;;
    esac

    log_info "Done!"
}

main
