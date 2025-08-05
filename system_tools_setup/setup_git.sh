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

