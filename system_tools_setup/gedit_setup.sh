#!/bin/sh
set -eu

SCRIPT_NAME=$(basename "$0")

usage() {
  cat <<EOF
Usage:
  ./$SCRIPT_NAME

Purpose:
  Apply a small set of preferred gedit editor settings.

Changes:
  - enables an 80-column right margin
  - sets the Cobalt color scheme
  - uses 4-space indentation

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

gsettings set org.gnome.gedit.preferences.editor display-right-margin true
gsettings set org.gnome.gedit.preferences.editor right-margin-position 80
gsettings set org.gnome.gedit.preferences.editor scheme 'cobalt'
gsettings set org.gnome.gedit.preferences.editor tabs-size 4
gsettings set org.gnome.gedit.preferences.editor insert-spaces true

echo "gedit configuration applied successfully."
