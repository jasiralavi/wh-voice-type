#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-0.1.0}"
PKG="whtype"
ARCH="all"

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SRC_DIR/deb-build"
DEBROOT="$BUILD_DIR/${PKG}_${VERSION}_${ARCH}"
OUT_DEB="$SRC_DIR/${PKG}_${VERSION}_${ARCH}.deb"

rm -rf "$BUILD_DIR"

mkdir -p "$DEBROOT/DEBIAN"
mkdir -p "$DEBROOT/usr/share/whtype"
mkdir -p "$DEBROOT/usr/bin"
mkdir -p "$DEBROOT/usr/share/doc/whtype"

cp -a "$SRC_DIR/bin" "$DEBROOT/usr/share/whtype/"
cp -a "$SRC_DIR/config" "$DEBROOT/usr/share/whtype/"
cp -a "$SRC_DIR/README.md" "$DEBROOT/usr/share/whtype/"
cp -a "$SRC_DIR/requirements.txt" "$DEBROOT/usr/share/whtype/"
cp -a "$SRC_DIR/repair.sh" "$DEBROOT/usr/share/whtype/"
cp -a "$SRC_DIR/install.sh" "$DEBROOT/usr/share/whtype/"
cp -a "$SRC_DIR/setup-shortcut.sh" "$DEBROOT/usr/share/whtype/"
cp -a "$SRC_DIR/setup-settings-launcher.sh" "$DEBROOT/usr/share/whtype/"

if [ -f "$SRC_DIR/LICENSE" ]; then
  cp -a "$SRC_DIR/LICENSE" "$DEBROOT/usr/share/doc/whtype/copyright"
fi

cat > "$DEBROOT/DEBIAN/control" <<CONTROL
Package: whtype
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Maintainer: Jasir Alavi <jasir@jasiralavi.com>
Depends: python3, python3-venv, python3-pip, python3-tk, pipewire-bin, sox, ydotool, wl-clipboard, coreutils, desktop-file-utils
Description: Local voice typing for GNOME/Linux using faster-whisper
 WhType records your voice, transcribes it locally using faster-whisper,
 and types the text into the active window.
CONTROL

cat > "$DEBROOT/DEBIAN/postinst" <<'POSTINST'
#!/bin/sh
set -e

if command -v systemctl >/dev/null 2>&1; then
  systemctl enable --now ydotoold >/dev/null 2>&1 || true
fi

exit 0
POSTINST

chmod 755 "$DEBROOT/DEBIAN/postinst"

cat > "$DEBROOT/usr/bin/whtype-setup" <<'SETUP'
#!/usr/bin/env bash
set -euo pipefail

TEMPLATE="/usr/share/whtype"
APPDIR="${XDG_DATA_HOME:-$HOME/.local/share}/whtype"

echo "Setting up WhType for current user..."
echo "User app folder: $APPDIR"
echo

mkdir -p "$APPDIR"

TMP_CONFIG=""
if [ -f "$APPDIR/config/settings.conf" ]; then
  TMP_CONFIG="$(mktemp)"
  cp "$APPDIR/config/settings.conf" "$TMP_CONFIG"
fi

cp -a "$TEMPLATE/." "$APPDIR/"

if [ -n "$TMP_CONFIG" ] && [ -f "$TMP_CONFIG" ]; then
  mkdir -p "$APPDIR/config"
  cp "$TMP_CONFIG" "$APPDIR/config/settings.conf"
  rm -f "$TMP_CONFIG"
fi

chmod +x "$APPDIR/bin/wh-type" "$APPDIR/bin/wh-type-toggle" "$APPDIR/bin/wh-type-settings"
chmod +x "$APPDIR/setup-shortcut.sh" "$APPDIR/setup-settings-launcher.sh" "$APPDIR/repair.sh"

echo "Creating Python virtual environment..."
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

echo
echo "Creating GNOME shortcut..."
"$APPDIR/setup-shortcut.sh" || true

echo
echo "Creating settings launcher..."
"$APPDIR/setup-settings-launcher.sh" || true

echo
echo "WhType setup complete."
echo "Shortcut: Super + R"
echo "Settings: search for 'WhType Settings'"
SETUP

chmod 755 "$DEBROOT/usr/bin/whtype-setup"

cat > "$DEBROOT/usr/bin/whtype" <<'WHTYPE'
#!/usr/bin/env bash
APPDIR="${XDG_DATA_HOME:-$HOME/.local/share}/whtype"

if [ ! -x "$APPDIR/bin/wh-type-toggle" ]; then
  echo "WhType is not set up for this user."
  echo "Run: whtype-setup"
  exit 1
fi

exec "$APPDIR/bin/wh-type-toggle" "$@"
WHTYPE

chmod 755 "$DEBROOT/usr/bin/whtype"

cat > "$DEBROOT/usr/bin/whtype-settings" <<'SETTINGS'
#!/usr/bin/env bash
APPDIR="${XDG_DATA_HOME:-$HOME/.local/share}/whtype"

if [ ! -x "$APPDIR/bin/wh-type-settings" ]; then
  echo "WhType is not set up for this user."
  echo "Run: whtype-setup"
  exit 1
fi

exec "$APPDIR/bin/wh-type-settings" "$@"
SETTINGS

chmod 755 "$DEBROOT/usr/bin/whtype-settings"

dpkg-deb --build --root-owner-group "$DEBROOT" "$OUT_DEB"

echo
echo "Built package:"
echo "$OUT_DEB"
