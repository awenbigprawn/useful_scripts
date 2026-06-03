#!/bin/sh

# Stop Ubuntu 24.04 from asking to fill the empty screen space
echo "Configuring Ubuntu window tiling..."
gsettings set org.gnome.shell.extensions.tiling-assistant enable-tiling-popup false

# Verify the setting was applied
RESULT=$(gsettings get org.gnome.shell.extensions.tiling-assistant enable-tiling-popup)
echo "Setting 'enable-tiling-popup' is now: $RESULT"

