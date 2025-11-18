#!/bin/bash

# Setup script for GitHub Environment Cloner
# This script creates a Python virtual environment and installs required dependencies

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"

echo "=========================================="
echo "Setting up Python Virtual Environment"
echo "=========================================="
echo ""

# Check if Python3 is available
if ! command -v python3 >/dev/null 2>&1; then
  echo "Error: Python3 is not installed."
  echo "Please install Python3 first: https://www.python.org/downloads/"
  exit 1
fi

# Check Python version (need 3.6+)
python_version=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
required_version="3.6"

if [ "$(printf '%s\n' "$required_version" "$python_version" | sort -V | head -n1)" != "$required_version" ]; then
  echo "Error: Python 3.6 or higher is required. Found: $python_version"
  exit 1
fi

echo "✓ Python3 found: $(python3 --version)"
echo ""

# Create virtual environment if it doesn't exist
if [ -d "$VENV_DIR" ]; then
  echo "Virtual environment already exists at: $VENV_DIR"
  read -p "Do you want to recreate it? (y/N): " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing existing virtual environment..."
    rm -rf "$VENV_DIR"
  else
    echo "Using existing virtual environment."
    echo ""
    echo "To activate the virtual environment manually:"
    echo "  source $VENV_DIR/bin/activate"
    exit 0
  fi
fi

echo "Creating virtual environment at: $VENV_DIR"
python3 -m venv "$VENV_DIR"

echo ""
echo "Activating virtual environment..."
source "$VENV_DIR/bin/activate"

echo "Upgrading pip..."
pip install --upgrade pip >/dev/null 2>&1

echo ""
echo "Installing PyNaCl..."
pip install pynacl >/dev/null 2>&1

echo ""
echo "=========================================="
echo "✓ Setup completed successfully!"
echo "=========================================="
echo ""
echo "The virtual environment is ready at: $VENV_DIR"
echo ""
echo "The main script will automatically use this virtual environment if it exists."
echo "You don't need to activate it manually - the script handles it automatically."
echo ""
echo "To verify the installation:"
echo "  source $VENV_DIR/bin/activate"
echo "  python3 -c 'import nacl; print(\"PyNaCl version:\", nacl.__version__)'"
echo "  deactivate"

