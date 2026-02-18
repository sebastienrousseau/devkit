#!/usr/bin/env bash
#
# Development Environment Setup Script
# Sets up all required tools and configurations for ecosystem development
#

set -euo pipefail
IFS=$'\n\t'

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

require_command() {
    command -v "$1" >/dev/null 2>&1 || {
        log_error "Required command not found: $1"
        return 1
    }
}

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Linux*)  echo "linux" ;;
        Darwin*) echo "macos" ;;
        *)       echo "unknown" ;;
    esac
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    local missing=()

    require_command git || missing+=("git")
    require_command curl || missing+=("curl")

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing[*]}"
        exit 1
    fi

    log_info "Prerequisites check passed"
}

# Install Rust
install_rust() {
    if command -v rustc &>/dev/null; then
        local version
        version=$(rustc --version | cut -d' ' -f2)
        log_info "Rust already installed: $version"
        return 0
    fi

    log_info "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"

    # Install common components
    rustup component add clippy rustfmt

    log_info "Rust installed successfully"
}

# Install Python tools
install_python() {
    if ! command -v python3 &>/dev/null; then
        log_warn "Python 3 not found, skipping Python setup"
        return 0
    fi

    log_info "Setting up Python environment..."

    # Install Poetry if not present
    if ! command -v poetry &>/dev/null; then
        log_info "Installing Poetry..."
        curl -sSL https://install.python-poetry.org | python3 -
    fi

    # Install common tools
    python3 -m pip install --user ruff mypy pytest 2>/dev/null || true

    log_info "Python setup complete"
}

# Install Node.js tools
install_node() {
    if ! command -v node &>/dev/null; then
        log_warn "Node.js not found, skipping Node setup"
        return 0
    fi

    log_info "Setting up Node.js environment..."

    # Install pnpm if not present
    if ! command -v pnpm &>/dev/null; then
        log_info "Installing pnpm..."
        npm install -g pnpm
    fi

    log_info "Node.js setup complete"
}

# Install Rust development tools
install_rust_tools() {
    if ! command -v cargo &>/dev/null; then
        return 0
    fi

    log_info "Installing Rust development tools..."

    local tools=(
        "cargo-audit"
        "cargo-watch"
        "cargo-edit"
    )

    for tool in "${tools[@]}"; do
        if ! cargo install --list | grep -q "^$tool "; then
            log_info "Installing $tool..."
            cargo install "$tool" 2>/dev/null || log_warn "Failed to install $tool"
        fi
    done

    log_info "Rust tools installed"
}

# Setup git hooks
setup_git_hooks() {
    log_info "Setting up git hooks..."

    local devkit_dir
    devkit_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    # Copy pre-commit hook
    if [[ -f "$devkit_dir/hooks/pre-commit" ]]; then
        log_info "Pre-commit hook available at: $devkit_dir/hooks/pre-commit"
    fi

    log_info "Git hooks ready"
}

# Setup editor configs
setup_editor() {
    log_info "Setting up editor configurations..."

    local devkit_dir
    devkit_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    # Create global editorconfig if not exists
    if [[ ! -f "$HOME/.editorconfig" ]] && [[ -f "$devkit_dir/configs/.editorconfig" ]]; then
        cp "$devkit_dir/configs/.editorconfig" "$HOME/.editorconfig"
        log_info "Created ~/.editorconfig"
    fi

    log_info "Editor configuration complete"
}

# Main
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║     Development Environment Setup            ║"
    echo "║     Sebastien Rousseau Ecosystem             ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"

    local os
    os=$(detect_os)
    log_info "Detected OS: $os"

    check_prerequisites
    install_rust
    install_python
    install_node
    install_rust_tools
    setup_git_hooks
    setup_editor

    echo ""
    log_info "Development environment setup complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Clone ecosystem repositories"
    echo "  2. Run 'cargo build' in Rust projects"
    echo "  3. Run 'poetry install' in Python projects"
    echo ""
}

main "$@"
