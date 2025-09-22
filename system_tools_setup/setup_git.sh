#!/bin/sh

# Set user information
# git config --global user.email "your-email@example.com"
# git config --global user.name "your username"

# Set Git aliases
git config --global alias.lg "log --decorate --oneline --graph"
git config --global alias.s "status"
git config --global alias.p "pull"
git config --global alias.cs "commit -s"

echo "Git configuration has been successfully applied."

# to make git = gti
ALIAS_CMD="alias gti='git'"

# the files to edit
CONFIG_FILES="$HOME/.bashrc $HOME/.profile $HOME/.zshrc"

for FILE in $CONFIG_FILES; do
    if [ -f "$FILE" ]; then
        # check if alias already exist
        if grep -Fxq "$ALIAS_CMD" "$FILE"; then
            echo "Alias already exists in $FILE"
        else
            echo "$ALIAS_CMD" >> "$FILE"
            echo "Alias added to $FILE"
        fi
    fi
done

# make available in current shell
echo "alias gti='git' finished, source ~/.bashrc to enable."

