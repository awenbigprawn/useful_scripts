#!/bin/bash

# --- Window Management Configuration Script ---
# Function: Verify Tiling Assistant, disable interference, and lock Z-order
# Usage: chmod +x fix-tiling-disable-popup.sh && ./fix-tiling-disable-popup.sh

echo "Starting window management optimization..."

# 1. Check if Tiling Assistant is installed
# It's an extension, so we check if the gsettings schema exists
if ! gsettings list-schemas | grep -q "org.gnome.shell.extensions.tiling-assistant"; then
    echo "[!] Error: Tiling Assistant extension is not installed."
    echo "    Please install it from the Extension Manager or GNOME Extensions website."
    exit 1
else
    echo "[√] Tiling Assistant extension detected."
fi

# 2. Disable Tiling Assistant popup to prevent UI interference
gsettings set org.gnome.shell.extensions.tiling-assistant enable-tiling-popup false
echo "[√] Disabled tiling assistant popup"

# 3. Disable GNOME native edge tiling to prevent auto-snapping into groups
gsettings set org.gnome.mutter edge-tiling false
echo "[√] Disabled edge tiling"

# 4. Disable focus change on pointer rest to prevent unexpected Z-order shifts[cite: 1]
gsettings set org.gnome.mutter focus-change-on-pointer-rest false
echo "[√] Disabled focus-change-on-pointer-rest"

# 5. Clear conflicting tiling keybindings to prevent accidental grouping[cite: 1]
gsettings set org.gnome.mutter.keybindings toggle-tiled-left "[]"
gsettings set org.gnome.mutter.keybindings toggle-tiled-right "[]"
gsettings set org.gnome.desktop.wm.keybindings maximize "[]"
gsettings set org.gnome.desktop.wm.keybindings unmaximize "[]"
echo "[√] Cleared conflicting tiling keybindings"

# 6. Verify and Report Configuration Status
POPUP_STATUS=$(gsettings get org.gnome.shell.extensions.tiling-assistant enable-tiling-popup)
EDGE_STATUS=$(gsettings get org.gnome.mutter edge-tiling)

echo "----------------------------------------"
echo "Configuration Summary:"
echo " - Tiling popup disabled: $POPUP_STATUS"
echo " - Edge tiling disabled: $EDGE_STATUS"
echo "Window management configuration complete."
echo "Please log out and log back in for changes to apply."
