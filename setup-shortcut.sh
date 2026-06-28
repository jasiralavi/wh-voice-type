#!/usr/bin/env bash
set -e

APPDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$APPDIR/config/settings.conf"
CMD="$APPDIR/bin/wh-type-toggle"

SHORTCUT="<Super>r"

if [ -f "$CONFIG" ]; then
  # shellcheck disable=SC1090
  source "$CONFIG"
  SHORTCUT="${SHORTCUT:-<Super>r}"
fi

SCHEMA="org.gnome.settings-daemon.plugins.media-keys"
KEY="custom-keybindings"
DIR="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/whtype/"

echo "Creating/updating GNOME shortcut for WhType..."
echo "Command: $CMD"
echo "Shortcut: $SHORTCUT"

CURRENT="$(gsettings get "$SCHEMA" "$KEY")"

NEW_LIST="$(python3 - <<PY
import ast

current = """$CURRENT"""
shortcut = "$DIR"

if current.startswith("@as "):
    current = current[4:].strip()

try:
    items = ast.literal_eval(current)
except Exception:
    items = []

if shortcut not in items:
    items.append(shortcut)

print(str(items))
PY
)"

gsettings set "$SCHEMA" "$KEY" "$NEW_LIST"

gsettings set "$SCHEMA.custom-keybinding:$DIR" name "WhType Voice Typing"
gsettings set "$SCHEMA.custom-keybinding:$DIR" command "$CMD"
gsettings set "$SCHEMA.custom-keybinding:$DIR" binding "$SHORTCUT"

echo "Shortcut applied."
