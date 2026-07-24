#!/bin/sh
set -eu

SCRIPT_NAME=$(basename "$0")

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME

Purpose:
  Remove snap packages, purge snapd, and delete common snap data directories.

What it changes:
  - unmounts snap core mounts when present
  - removes installed snap packages
  - purges snapd
  - deletes ~/snap, /var/snap, and /var/lib/snapd
  - holds firefox and snapd in apt

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

sudo umount /snap/core* -lf || true

while [ "$(snap list 2> /dev/null | wc -l)" -ne 0 ]
do
  for pkg in $(snap list | awk '{print $1 }' | tail -n +2)
  do
    sudo snap remove "${pkg}" || true
  done
done

sudo apt remove -y snapd --purge

sudo rm -rf ~/snap
sudo rm -rf /var/snap
sudo rm -rf /var/lib/snapd

sudo apt-mark hold firefox snapd
