#!/bin/sh
set -ex

script_dir=$(readlink -e "$(dirname "$0")")

cd "${script_dir}"

echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
echo "options nouveau modeset=0" | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf

# You need to initramfs & reboot the first time you do that:
#   sudo update-initramfs -u
#   reboot

nvidia_run_file=NVIDIA-Linux-x86_64-550.120.run

wget --continue https://us.download.nvidia.com/XFree86/Linux-x86_64/550.120/${nvidia_run_file}

sudo IGNORE_PREEMPT_RT_PRESENCE=1 bash "${nvidia_run_file}" --silent
