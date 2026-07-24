#!/bin/sh
set -eu

SCRIPT_NAME=$(basename "$0")

usage() {
  cat <<EOF
Usage:
  ./$SCRIPT_NAME

Purpose:
  Replace ~/.tmux.conf with a small preferred tmux configuration.

What it sets:
  - mouse support enabled
  - prefix changed from Ctrl+b to Ctrl+a
  - reloads the config immediately when run inside tmux

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

cat <<EOL > ~/.tmux.conf
# Enable mouse support
set -g mouse on

# Increase scrollback history limit
# set -g history-limit 10000

# Change prefix key from Ctrl+b to Ctrl+a
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix
EOL

if [ -n "${TMUX:-}" ]; then
    tmux source-file ~/.tmux.conf
    echo "Tmux configuration reloaded."
else
    echo "Tmux configuration file created. Start a new tmux session to apply the changes."
fi
