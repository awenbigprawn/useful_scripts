#!/bin/sh

# Create or overwrite the .tmux.conf file with the desired configuration
cat <<EOL > ~/.tmux.conf
# Enable mouse support
set -g mouse on

# Increase scrollback history limit
# set -g history-limit 10000

# Change prefix key from Ctrl+b to Ctrl+a
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix
EOL

# Check if inside a tmux session and reload the configuration
if [ -n "$TMUX" ]; then
    tmux source-file ~/.tmux.conf
    echo "Tmux configuration reloaded."
else
    echo "Tmux configuration file created. Start a new tmux session to apply the changes."
fi
