#!/usr/bin/env bash
set -e

echo "=== Python WSL2 Environment Bootstrap ==="

# Check Python 3
if ! command -v python3 &>/dev/null; then
    echo "Python 3 not found. Installing python3, python3-venv, and python3-pip..."
    sudo apt update && sudo apt install -y python3 python3-venv python3-pip
fi

# Check if ensurepip/venv is functional
if ! python3 -c "import ensurepip" &>/dev/null; then
    echo "ensurepip / python3-venv missing on system. Installing required packages..."
    PY_VER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    sudo apt update && sudo apt install -y python3-venv python3-pip "python${PY_VER}-venv" || sudo apt install -y python3-venv python3-pip
fi

# Create virtual environment if not present
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment in .venv..."
    python3 -m venv .venv
else
    echo "Existing .venv detected."
fi

# Activate virtual environment
source .venv/bin/activate

# Upgrade pip & install requirements
python3 -m pip install --upgrade pip

if [ -f "requirements.txt" ]; then
    echo "Installing dependencies from requirements.txt..."
    pip install -r requirements.txt
fi

echo "=== Setup complete! Virtual environment is ready in .venv ==="
