#!/usr/bin/env bash
set -e

APPDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing WhType..."
echo "App folder: $APPDIR"
echo

echo "Installing system dependencies..."
sudo apt update
sudo apt install -y python3 python3-venv python3-pip python3-tk pipewire-bin sox ydotool wl-clipboard coreutils

echo
echo "Starting ydotoold..."
sudo systemctl enable --now ydotoold || true

echo
echo "Creating Python environment..."
cd "$APPDIR"
python3 -m venv .venv
.venv/bin/python -m ensurepip --upgrade
.venv/bin/python -m pip install --upgrade pip wheel setuptools
.venv/bin/python -m pip install -r requirements.txt

echo
echo "Preloading base.en model..."
export HF_HOME="$APPDIR/models/huggingface"
export HF_HUB_CACHE="$HF_HOME/hub"

.venv/bin/python - <<'PY'
from faster_whisper import WhisperModel
print("Loading base.en...")
model = WhisperModel("base.en", compute_type="int8")
print("base.en ready")
PY

chmod +x "$APPDIR/bin/wh-type" "$APPDIR/bin/wh-type-toggle" "$APPDIR/bin/wh-type-settings" 2>/dev/null || true
chmod +x "$APPDIR/setup-shortcut.sh" "$APPDIR/setup-settings-launcher.sh" 2>/dev/null || true

echo
echo "Creating Super+R shortcut..."
if [ -f "$APPDIR/setup-shortcut.sh" ]; then
  "$APPDIR/setup-shortcut.sh" || true
else
  echo "setup-shortcut.sh not found. Skipping shortcut setup."
fi

echo
echo "Creating WhType Settings app launcher..."
if [ -f "$APPDIR/setup-settings-launcher.sh" ]; then
  "$APPDIR/setup-settings-launcher.sh" || true
else
  echo "setup-settings-launcher.sh not found. Skipping settings launcher."
fi

echo
echo "WhType installed."
echo
echo "Shortcut:"
echo "  Super + R"
echo
echo "Settings:"
echo "  Search for 'WhType Settings' in the app menu"
echo
echo "Manual command:"
echo "  $APPDIR/bin/wh-type-toggle"
