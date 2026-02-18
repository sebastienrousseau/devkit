#!/bin/bash
# Development environment setup script

set -euo pipefail

echo "Setting up development environment..."

# Check prerequisites
command -v git >/dev/null 2>&1 || { echo "git is required"; exit 1; }
command -v cargo >/dev/null 2>&1 || { echo "cargo is required"; exit 1; }

echo "Environment ready!"
