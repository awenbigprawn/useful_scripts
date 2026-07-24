#!/bin/sh

set -eu

SCRIPT_NAME=$(basename "$0")
LOCAL_BIN_DIR="$HOME/.local/bin"
GTI_WRAPPER="$LOCAL_BIN_DIR/gti"
PATH_EXPORT='export PATH="$HOME/.local/bin:$PATH"'
LEGACY_ALIAS="alias gti='git'"
CONFIG_FILES="$HOME/.bashrc $HOME/.profile $HOME/.zshrc"

usage() {
  cat <<EOF
Usage:
  ./$SCRIPT_NAME

Purpose:
  Configure a few global Git aliases and install a real 'gti' wrapper command.

What it changes:
  - git alias.lg, alias.s, alias.p, alias.cs
  - ~/.local/bin/gti wrapper that forwards to git
  - ~/.local/bin added to PATH in common shell config files
  - removes an old alias gti='git' if present

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

# Set user information
# git config --global user.email "your-email@example.com"
# git config --global user.name "your username"

# Set Git aliases
git config --global alias.lg "log --decorate --oneline --graph"
git config --global alias.s "status"
git config --global alias.p "pull"
git config --global alias.cs "commit -s"

echo "Git configuration has been successfully applied."

mkdir -p "$LOCAL_BIN_DIR"

cat > "$GTI_WRAPPER" <<'WRAPPER'
#!/bin/sh
exec git "$@"
WRAPPER
chmod 755 "$GTI_WRAPPER"
echo "Installed wrapper command: $GTI_WRAPPER"

for FILE in $CONFIG_FILES; do
    if [ -f "$FILE" ]; then
        if grep -Fxq "$LEGACY_ALIAS" "$FILE"; then
            tmp_file=$(mktemp)
            grep -Fvx "$LEGACY_ALIAS" "$FILE" > "$tmp_file" || true
            mv "$tmp_file" "$FILE"
            echo "Removed legacy alias from $FILE"
        fi

        if grep -Fxq "$PATH_EXPORT" "$FILE"; then
            echo "PATH entry already exists in $FILE"
        else
            echo "$PATH_EXPORT" >> "$FILE"
            echo "Added ~/.local/bin to PATH in $FILE"
        fi
    fi
done

case ":$PATH:" in
    *":$LOCAL_BIN_DIR:"*)
        echo "gti is available in the current shell."
        ;;
    *)
        echo 'Run: export PATH="$HOME/.local/bin:$PATH"'
        echo "Or open a new shell, then use: gti diff"
        ;;
esac
