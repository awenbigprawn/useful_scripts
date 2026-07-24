#!/bin/bash
set -euo pipefail

SCRIPT_NAME=$(basename "$0")
FILE="/etc/modprobe.d/alsa-base.conf"
LINE="options snd-hda-intel model=headset-mode"

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME

Purpose:
  Add an ALSA modprobe option that can improve headset detection at boot.

What it changes:
  Appends the following line to $FILE if it is not already present:
    $LINE

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

echo "Checking audio configuration..."

if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script with sudo!"
  exit 1
fi

if [ ! -f "$FILE" ]; then
    echo "File $FILE not found, creating new file..."
    touch "$FILE"
fi

if grep -Fxq "$LINE" "$FILE"; then
    echo "Configuration already exists. No changes made."
else
    echo "Writing configuration to $FILE..."
    printf '
# Fix headphone detection at boot
%s
' "$LINE" >> "$FILE"
    echo "Done!"
fi

echo "-----------------------------------------------"
echo "Please restart your computer for changes to take effect."
echo "Alternatively, try: sudo alsa force-reload"
echo "-----------------------------------------------"
