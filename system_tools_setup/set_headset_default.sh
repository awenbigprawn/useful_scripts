#!/bin/bash

# Define target file and the configuration line
FILE="/etc/modprobe.d/alsa-base.conf"
LINE="options snd-hda-intel model=headset-mode"

echo "Checking audio configuration..."

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script with sudo!"
  exit 1
fi

# Create file if it does not exist
if [ ! -f "$FILE" ]; then
    echo "File $FILE not found, creating new file..."
    touch "$FILE"
fi

# Check if the configuration already exists to avoid duplicates
if grep -Fxq "$LINE" "$FILE"; then
    echo "Configuration already exists. No changes made."
else
    echo "Writing configuration to $FILE..."
    # Append the line to the end of the file
    echo -e "\n# Fix headphone detection at boot\n$LINE" >> "$FILE"
    echo "Done!"
fi

echo "-----------------------------------------------"
echo "Please restart your computer for changes to take effect."
echo "Alternatively, try: sudo alsa force-reload"
echo "-----------------------------------------------"
