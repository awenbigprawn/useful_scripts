#!/bin/sh
set -eu

SCRIPT_NAME=$(basename "$0")
DEFAULT_PATTERN="safebot"
DEFAULT_INTERVAL="0.1"

usage() {
  cat <<EOF
Usage:
  ./$SCRIPT_NAME [pattern] [interval_seconds]

Purpose:
  Watch thread scheduling information for processes matching a pattern.

Arguments:
  pattern               Case-insensitive process name filter (default: $DEFAULT_PATTERN)
  interval_seconds      Refresh interval for watch (default: $DEFAULT_INTERVAL)

Options:
  -h, --help            Show this help message and exit

Example:
  ./$SCRIPT_NAME chrome 0.5
EOF
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
esac

if [ $# -gt 2 ]; then
  echo "ERROR: Too many arguments." >&2
  usage >&2
  exit 2
fi

PATTERN="${1:-$DEFAULT_PATTERN}"
INTERVAL="${2:-$DEFAULT_INTERVAL}"

watch -n"$INTERVAL" "ps -eL -o pid,tid,comm,cls,pri,rtprio,psr | grep -i '$PATTERN' | sort -f -k3"
