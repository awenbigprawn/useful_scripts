#!/bin/bash
set -euo pipefail

SCRIPT_NAME=$(basename "$0")

usage() {
  cat <<EOF
Usage:
  ./$SCRIPT_NAME

Purpose:
  Adjust GNOME and Tiling Assistant settings to reduce popup and auto-tiling interference.

What it changes:
  - disables the Tiling Assistant popup
  - disables GNOME edge tiling
  - disables focus-change-on-pointer-rest
  - clears several tiling-related keybindings

Options:
  -h, --help            Show this help message and exit
EOF
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
  "")
    ;;
  *)
    echo "ERROR: $SCRIPT_NAME does not accept positional arguments." >&2
    usage >&2
    exit 2
    ;;
esac

echo "Starting window management optimization..."

if ! gsettings list-schemas | grep -q "org.gnome.shell.extensions.tiling-assistant"; then
    echo "[!] Error: Tiling Assistant extension is not installed."
    echo "    Please install it from the Extension Manager or GNOME Extensions website."
    exit 1
else
    echo "[√] Tiling Assistant extension detected."
fi

gsettings set org.gnome.shell.extensions.tiling-assistant enable-tiling-popup false
echo "[√] Disabled tiling assistant popup"

gsettings set org.gnome.mutter edge-tiling false
echo "[√] Disabled edge tiling"

gsettings set org.gnome.mutter focus-change-on-pointer-rest false
echo "[√] Disabled focus-change-on-pointer-rest"

gsettings set org.gnome.mutter.keybindings toggle-tiled-left "[]"
gsettings set org.gnome.mutter.keybindings toggle-tiled-right "[]"
gsettings set org.gnome.desktop.wm.keybindings maximize "[]"
gsettings set org.gnome.desktop.wm.keybindings unmaximize "[]"
echo "[√] Cleared conflicting tiling keybindings"

POPUP_STATUS=$(gsettings get org.gnome.shell.extensions.tiling-assistant enable-tiling-popup)
EDGE_STATUS=$(gsettings get org.gnome.mutter edge-tiling)

echo "----------------------------------------"
echo "Configuration Summary:"
echo " - Tiling popup disabled: $POPUP_STATUS"
echo " - Edge tiling disabled: $EDGE_STATUS"
echo "Window management configuration complete."
echo "Please log out and log back in for changes to apply."
