#!/bin/sh
set -e

sudo umount /snap/core* -lf || true

while [ $(snap list 2> /dev/null | wc -l ) -ne 0 ]
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

# prevent snapd & firefox to update with apt upgrade:
sudo apt-mark hold firefox snapd
