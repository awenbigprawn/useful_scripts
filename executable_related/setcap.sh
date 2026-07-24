#!/bin/sh
set -eu

SCRIPT_NAME=$(basename "$0")

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME <target_binary>

Purpose:
  Grant cap_sys_nice to a binary so it can request elevated scheduling priority.

Arguments:
  target_binary         Path to the executable that should receive the capability

Options:
  -h, --help            Show this help message and exit
EOF
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
esac

if [ $# -ne 1 ]; then
  echo "ERROR: Expected exactly one argument: <target_binary>" >&2
  usage >&2
  exit 2
fi

set -x
target_bin=$1

sudo setcap cap_sys_nice+ep "${target_bin}"
