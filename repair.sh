#!/usr/bin/env bash
set -e

APPDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$APPDIR"

echo "Removing old venv..."
rm -rf .venv

echo "Recreating venv..."
python3 -m venv .venv
.venv/bin/python -m ensurepip --upgrade
.venv/bin/python -m pip install --upgrade pip wheel setuptools
.venv/bin/python -m pip install -r requirements.txt

echo "Restarting ydotoold..."
sudo systemctl restart ydotoold || true

echo "Repair complete."
