#!/bin/sh
# Configure Rime Chinese Pinyin on Ubuntu/GNOME with IBus.
# - Installs ibus-rime and Luna Pinyin data
# - Enables only Simplified Luna Pinyin
# - Enables fuzzy finals for in<->ing and en<->eng
# - Uses a horizontal candidate window
# - Adds Rime to GNOME input sources when possible
# - Backs up existing configuration files before replacing them

set -eu

SCRIPT_NAME=$(basename "$0")

usage() {
    cat <<EOF
Usage:
  ./$SCRIPT_NAME

Purpose:
  Install and configure IBus Rime with Simplified Luna Pinyin on Ubuntu/GNOME.

What it does:
  - installs ibus-rime and rime-data-luna-pinyin
  - enables only luna_pinyin_simp
  - enables fuzzy finals for in/ing and en/eng
  - sets a horizontal candidate window
  - adds Rime to GNOME input sources when possible
  - restarts IBus to trigger redeployment

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
        printf '%s
' "Error: $SCRIPT_NAME does not accept positional arguments." >&2
        usage >&2
        exit 2
        ;;
esac

if [ "$(id -u)" -eq 0 ]; then
    printf '%s
' "Error: run this script as your normal desktop user, not with sudo."
    printf '%s
' "The script will invoke sudo only for package installation."
    exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
    printf '%s
' "Error: apt-get was not found. This script is intended for Ubuntu/Debian."
    exit 1
fi

printf '%s
' "[1/6] Installing IBus Rime and Luna Pinyin data..."
need_install=0
for package in ibus-rime rime-data-luna-pinyin; do
    if ! dpkg-query -W -f='${db:Status-Status}' "$package" 2>/dev/null | grep -qx 'installed'; then
        need_install=1
    fi
done

if [ "$need_install" -eq 1 ]; then
    sudo apt-get update
    sudo apt-get install -y ibus-rime rime-data-luna-pinyin
else
    printf '%s
' "Required packages are already installed."
fi

RIME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ibus/rime"
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
mkdir -p "$RIME_DIR"

install_config() {
    target=$1
    tmp_file=$(mktemp)
    cat > "$tmp_file"

    if [ -f "$target" ] && cmp -s "$tmp_file" "$target"; then
        rm -f "$tmp_file"
        printf '%s
' "Unchanged: $target"
        return
    fi

    if [ -e "$target" ]; then
        backup="${target}.bak.${TIMESTAMP}"
        cp -p "$target" "$backup"
        printf '%s
' "Backup:   $backup"
    fi

    mv "$tmp_file" "$target"
    chmod 600 "$target"
    printf '%s
' "Written:  $target"
}

printf '%s
' "[2/6] Selecting Simplified Luna Pinyin..."
install_config "$RIME_DIR/default.custom.yaml" <<'YAML'
patch:
  schema_list:
    - schema: luna_pinyin_simp
YAML

printf '%s
' "[3/6] Enabling fuzzy finals for in/ing and en/eng..."
install_config "$RIME_DIR/luna_pinyin_simp.custom.yaml" <<'YAML'
patch:
  speller/algebra:
    - derive/^([a-z]+)ing$/$1in/
    - derive/^([a-z]+)in$/$1ing/
    - derive/^([a-z]+)eng$/$1en/
    - derive/^([a-z]+)en$/$1eng/
YAML

printf '%s
' "[4/6] Configuring a horizontal candidate window..."
install_config "$RIME_DIR/ibus_rime.custom.yaml" <<'YAML'
patch:
  "style/horizontal": true
YAML

printf '%s
' "[5/6] Adding Rime to GNOME input sources when available..."
if command -v gsettings >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
    current_sources=$(gsettings get org.gnome.desktop.input-sources sources 2>/dev/null || true)

    if [ -n "$current_sources" ]; then
        new_sources=$(python3 - "$current_sources" <<'PY2'
import ast
import sys

raw = sys.argv[1].strip()
if raw.startswith("@a(ss) "):
    raw = raw[len("@a(ss) "):]

try:
    sources = list(ast.literal_eval(raw))
except (SyntaxError, ValueError, TypeError):
    raise SystemExit(1)

rime = ("ibus", "rime")
if rime not in sources:
    sources.append(rime)

print(repr(sources))
PY2
        ) || new_sources=""

        if [ -n "$new_sources" ]; then
            gsettings set org.gnome.desktop.input-sources sources "$new_sources"
            printf '%s
' "Rime is present in the GNOME input-source list."
        else
            printf '%s
' "Could not parse GNOME input sources; add Chinese (Rime) in Settings manually."
        fi
    else
        printf '%s
' "No active GNOME settings session; add Chinese (Rime) in Settings manually."
    fi
else
    printf '%s
' "gsettings/python3 unavailable; add Chinese (Rime) in Settings manually."
fi

printf '%s
' "[6/6] Triggering Rime redeployment and restarting IBus..."
touch "$RIME_DIR"

if command -v ibus >/dev/null 2>&1; then
    if ! ibus restart; then
        printf '%s
' "'ibus restart' failed; trying ibus-daemon -drx..."
        ibus-daemon -drx >/tmp/ibus-rime-restart.log 2>&1 &
    fi
else
    printf '%s
' "IBus command not found. Log out and log back in to activate Rime."
fi

printf '
%s
' "Rime setup completed."
printf '%s
' "Wait until the 'Rime is under maintenance' message disappears, then select Rime and type Chinese."
printf '%s
' "Configuration directory: $RIME_DIR"
