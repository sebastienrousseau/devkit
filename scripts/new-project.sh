#!/usr/bin/env bash
#
# New Project Scaffolding Script
# Creates a new project with ecosystem standards
#

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

usage() {
    cat <<EOF
Usage: $(basename "$0") <language> <name> [description]

Languages:
  rust    - Create a new Rust library
  python  - Create a new Python package
  node    - Create a new Node.js package

Example:
  $(basename "$0") rust my-library "A useful Rust library"
EOF
    exit 1
}

# Get devkit directory
DEVKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Create Rust project
create_rust() {
    local name="$1"
    local description="${2:-A Rust library}"

    log_info "Creating Rust project: $name"

    cargo new --lib "$name"
    cd "$name"

    # Update Cargo.toml
    cat > Cargo.toml <<EOF
[package]
name = "$name"
version = "0.1.0"
edition = "2021"
authors = ["Sebastien Rousseau <sebastian.rousseau@gmail.com>"]
description = "$description"
license = "MIT OR Apache-2.0"
repository = "https://github.com/sebastienrousseau/$name"
documentation = "https://docs.rs/$name"
readme = "README.md"

[dependencies]

[dev-dependencies]
EOF

    # Create README
    cat > README.md <<EOF
# $name

$description

## Installation

\`\`\`toml
[dependencies]
$name = "0.1.0"
\`\`\`

## Usage

\`\`\`rust
use $name::*;
\`\`\`

## License

Dual-licensed under [MIT](LICENSE-MIT) and [Apache-2.0](LICENSE-APACHE).
EOF

    # Add license files
    cp "$DEVKIT_DIR/templates/LICENSE-MIT" . 2>/dev/null || true
    cp "$DEVKIT_DIR/templates/LICENSE-APACHE" . 2>/dev/null || true

    log_info "Rust project created: $name"
}

# Create Python project
create_python() {
    local name="$1"
    local description="${2:-A Python package}"
    local package_name="${name//-/_}"

    log_info "Creating Python project: $name"

    mkdir -p "$name/src/$package_name" "$name/tests"
    cd "$name"

    # Create pyproject.toml
    cat > pyproject.toml <<EOF
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "$name"
version = "0.1.0"
description = "$description"
authors = [{name = "Sebastien Rousseau", email = "sebastian.rousseau@gmail.com"}]
license = "MIT OR Apache-2.0"
readme = "README.md"
requires-python = ">=3.9"
dependencies = []

[project.optional-dependencies]
dev = ["pytest", "pytest-cov", "ruff", "mypy"]
EOF

    # Create package init
    cat > "src/$package_name/__init__.py" <<EOF
"""$description"""

__version__ = "0.1.0"
EOF

    # Create README
    cat > README.md <<EOF
# $name

$description

## Installation

\`\`\`bash
pip install $name
\`\`\`

## Usage

\`\`\`python
import $package_name
\`\`\`

## License

Dual-licensed under [MIT](LICENSE-MIT) and [Apache-2.0](LICENSE-APACHE).
EOF

    # Create test file
    cat > tests/__init__.py <<EOF
EOF

    cat > "tests/test_${package_name}.py" <<EOF
"""Tests for $package_name."""

def test_import():
    import $package_name
    assert $package_name.__version__ == "0.1.0"
EOF

    log_info "Python project created: $name"
}

# Create Node project
create_node() {
    local name="$1"
    local description="${2:-A Node.js package}"

    log_info "Creating Node.js project: $name"

    mkdir -p "$name/src" "$name/tests"
    cd "$name"

    # Create package.json
    cat > package.json <<EOF
{
  "name": "@sebastienrousseau/$name",
  "version": "0.1.0",
  "description": "$description",
  "type": "module",
  "main": "./dist/index.js",
  "types": "./dist/index.d.ts",
  "exports": {
    ".": {
      "import": "./dist/index.js",
      "types": "./dist/index.d.ts"
    }
  },
  "scripts": {
    "build": "tsup",
    "test": "vitest",
    "lint": "eslint src/",
    "typecheck": "tsc --noEmit"
  },
  "engines": {
    "node": ">=18"
  },
  "author": "Sebastien Rousseau <sebastian.rousseau@gmail.com>",
  "license": "MIT OR Apache-2.0"
}
EOF

    # Create tsconfig.json
    cat > tsconfig.json <<EOF
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "declaration": true,
    "outDir": "dist"
  },
  "include": ["src/**/*"]
}
EOF

    # Create source file
    cat > src/index.ts <<EOF
/**
 * $description
 */

export const VERSION = "0.1.0";
EOF

    # Create README
    cat > README.md <<EOF
# $name

$description

## Installation

\`\`\`bash
pnpm add @sebastienrousseau/$name
\`\`\`

## Usage

\`\`\`typescript
import { VERSION } from '@sebastienrousseau/$name';
\`\`\`

## License

Dual-licensed under [MIT](LICENSE-MIT) and [Apache-2.0](LICENSE-APACHE).
EOF

    log_info "Node.js project created: $name"
}

# Main
main() {
    if [[ $# -lt 2 ]]; then
        usage
    fi

    local language="$1"
    local name="$2"
    local description="${3:-}"

    case "$language" in
        rust)
            create_rust "$name" "$description"
            ;;
        python)
            create_python "$name" "$description"
            ;;
        node)
            create_node "$name" "$description"
            ;;
        *)
            log_error "Unknown language: $language"
            usage
            ;;
    esac

    echo ""
    log_info "Project scaffolded successfully!"
    echo ""
    echo "Next steps:"
    echo "  cd $name"
    echo "  git init"
    echo "  # Start coding!"
}

main "$@"
