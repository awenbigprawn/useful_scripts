#!/bin/bash
set -euo pipefail

SCRIPT_NAME=$(basename "$0")

usage() {
  cat <<EOF
Usage:
  ./$SCRIPT_NAME

Purpose:
  Disable the Tiling Assistant half-screen popup while keeping normal tiling shortcuts.

What it changes:
  - disables the Tiling Assistant popup that asks what to place in the other half
  - keeps Super+Left and Super+Right available for normal half-screen tiling

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

echo "Disabling the Tiling Assistant popup..."

if ! gsettings list-schemas | grep -q "org.gnome.shell.extensions.tiling-assistant"; then
    echo "[!] Error: Tiling Assistant extension is not installed."
    echo "    Please install it from the Extension Manager or GNOME Extensions website."
    exit 1
else
    echo "[√] Tiling Assistant extension detected."
fi

gsettings set org.gnome.shell.extensions.tiling-assistant enable-tiling-popup false
echo "[√] Disabled tiling assistant popup"

POPUP_STATUS=$(gsettings get org.gnome.shell.extensions.tiling-assistant enable-tiling-popup)
LEFT_BINDING=$(gsettings get org.gnome.mutter.keybindings toggle-tiled-left)
RIGHT_BINDING=$(gsettings get org.gnome.mutter.keybindings toggle-tiled-right)

echo "----------------------------------------"
echo "Configuration Summary:"
echo " - Tiling popup disabled: $POPUP_STATUS"
echo " - Left half-screen shortcut: $LEFT_BINDING"
echo " - Right half-screen shortcut: $RIGHT_BINDING"
echo "Done."
