#!/usr/bin/env bash
set -e

APPDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESKTOP_FILE="$HOME/.local/share/applications/whtype-settings.desktop"

mkdir -p "$HOME/.local/share/applications"

cat > "$DESKTOP_FILE" <<DESKTOP
[Desktop Entry]
Type=Application
Name=WhType Settings
Comment=Configure WhType voice typing
Exec=$APPDIR/bin/wh-type-settings
Icon=audio-input-microphone
Terminal=false
Categories=Utility;Settings;
DESKTOP

chmod +x "$DESKTOP_FILE"

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$HOME/.local/share/applications" || true
fi

echo "WhType Settings launcher created."
echo "Open it from the app menu by searching: WhType Settings"
