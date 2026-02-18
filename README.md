# Devkit

Developer tooling and environment configuration for the Sebastien Rousseau ecosystem.

## Overview

Devkit provides scripts, configurations, and tools to streamline development workflows across the ecosystem. It ensures consistent development environments and coding practices.

## Quick Start

```bash
# Clone devkit
git clone https://github.com/sebastienrousseau/devkit.git
cd devkit

# Run setup
./scripts/setup.sh
```

## Contents

```
devkit/
├── scripts/
│   ├── setup.sh          # Environment setup script
│   └── new-project.sh    # Project scaffolding
├── hooks/
│   └── pre-commit        # Git pre-commit hook
├── configs/
│   └── .editorconfig     # Editor configuration
└── templates/
    └── rust/             # Rust project templates
```

## Scripts

### Environment Setup

Sets up your development environment with all required tools:

```bash
./scripts/setup.sh
```

This installs/configures:
- Rust toolchain with clippy and rustfmt
- Python tools (Poetry, ruff, mypy)
- Node.js tools (pnpm)
- Rust development tools (cargo-audit, cargo-watch)
- Git hooks
- Editor configurations

### Project Scaffolding

Create new projects following ecosystem standards:

```bash
# Create a Rust library
./scripts/new-project.sh rust my-library "A useful library"

# Create a Python package
./scripts/new-project.sh python my-package "A Python package"

# Create a Node.js package
./scripts/new-project.sh node my-package "A Node package"
```

## Git Hooks

### Pre-commit Hook

The pre-commit hook runs automatic checks before each commit:

- **Rust**: Format check (rustfmt), linting (clippy)
- **Python**: Format and lint check (ruff)
- **JavaScript**: Format check (prettier), linting (eslint)
- **Shell**: Linting (shellcheck)
- **Secrets**: Scans for potential secrets/credentials

#### Installation

```bash
# In your project directory
cp /path/to/devkit/hooks/pre-commit .git/hooks/
chmod +x .git/hooks/pre-commit
```

Or link globally:

```bash
git config --global core.hooksPath /path/to/devkit/hooks
```

## Editor Configuration

### EditorConfig

Copy the `.editorconfig` to your home directory for consistent formatting:

```bash
cp configs/.editorconfig ~/.editorconfig
```

Settings include:
- UTF-8 encoding
- LF line endings
- Language-specific indentation
- Trailing whitespace trimming

## Requirements

### Required
- Git 2.0+
- curl

### Language-Specific
- **Rust**: rustup, cargo
- **Python**: Python 3.9+, pip
- **Node.js**: Node 18+, npm

## Integration with Pipelines

Devkit works seamlessly with the pipelines repository:

1. Set up your environment with `devkit/scripts/setup.sh`
2. Create projects with `devkit/scripts/new-project.sh`
3. Projects automatically get CI/CD via `pipelines` templates
4. Pre-commit hooks ensure code quality before push

## License

Dual-licensed under [MIT](LICENSE-MIT) and [Apache-2.0](LICENSE-APACHE).
