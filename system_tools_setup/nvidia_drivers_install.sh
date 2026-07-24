#!/bin/sh
set -eu

SCRIPT_NAME=$(basename "$0")
NVIDIA_RUN_FILE="NVIDIA-Linux-x86_64-550.120.run"
NVIDIA_URL="https://us.download.nvidia.com/XFree86/Linux-x86_64/550.120/${NVIDIA_RUN_FILE}"

usage() {
  cat <<EOF
Usage:
  ./$SCRIPT_NAME

Purpose:
  Download and run a specific NVIDIA driver installer after disabling nouveau.

What it does:
  - writes a nouveau blacklist file under /etc/modprobe.d
  - downloads $NVIDIA_RUN_FILE
  - runs the NVIDIA installer in silent mode with sudo

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

set -x
script_dir=$(readlink -e "$(dirname "$0")")
cd "${script_dir}"

echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
echo "options nouveau modeset=0" | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf

# You need to initramfs & reboot the first time you do that:
#   sudo update-initramfs -u
#   reboot

wget --continue "$NVIDIA_URL"

sudo IGNORE_PREEMPT_RT_PRESENCE=1 bash "$NVIDIA_RUN_FILE" --silent
