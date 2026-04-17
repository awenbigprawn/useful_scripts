#!/bin/sh
# Configure gedit editor preferences.

# Display right margin at column 80
gsettings set org.gnome.gedit.preferences.editor display-right-margin true
gsettings set org.gnome.gedit.preferences.editor right-margin-position 80

# Use Cobalt color scheme
gsettings set org.gnome.gedit.preferences.editor scheme 'cobalt'
#gsettings set org.gnome.gedit.preferences.editor style-scheme 'cobalt'

# Set tab width to 4
gsettings set org.gnome.gedit.preferences.editor tabs-size 4

# Insert spaces instead of tabs
gsettings set org.gnome.gedit.preferences.editor insert-spaces true

echo "gedit configuration applied successfully."

