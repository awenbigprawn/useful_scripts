#!/bin/sh
# Configure Rime Chinese Pinyin on Ubuntu/GNOME with IBus.
# - Installs ibus-rime and Luna Pinyin data
# - Enables only Simplified Luna Pinyin
# - Uses a horizontal candidate window
# - Adds Rime to GNOME input sources when possible
# - Backs up existing configuration files before replacing them

set -eu

if [ "$(id -u)" -eq 0 ]; then
    printf '%s\n' "Error: run this script as your normal desktop user, not with sudo."
    printf '%s\n' "The script will invoke sudo only for package installation."
    exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
    printf '%s\n' "Error: apt-get was not found. This script is intended for Ubuntu/Debian."
    exit 1
fi

printf '%s\n' "[1/5] Installing IBus Rime and Luna Pinyin data..."
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
    printf '%s\n' "Required packages are already installed."
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
        printf '%s\n' "Unchanged: $target"
        return
    fi

    if [ -e "$target" ]; then
        backup="${target}.bak.${TIMESTAMP}"
        cp -p "$target" "$backup"
        printf '%s\n' "Backup:   $backup"
    fi

    mv "$tmp_file" "$target"
    chmod 600 "$target"
    printf '%s\n' "Written:  $target"
}

printf '%s\n' "[2/5] Selecting Simplified Luna Pinyin..."
install_config "$RIME_DIR/default.custom.yaml" <<'YAML'
patch:
  schema_list:
    - schema: luna_pinyin_simp
YAML

printf '%s\n' "[3/5] Configuring a horizontal candidate window..."
install_config "$RIME_DIR/ibus_rime.custom.yaml" <<'YAML'
patch:
  "style/horizontal": true
YAML

printf '%s\n' "[4/5] Adding Rime to GNOME input sources when available..."
if command -v gsettings >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
    current_sources=$(gsettings get org.gnome.desktop.input-sources sources 2>/dev/null || true)

    if [ -n "$current_sources" ]; then
        new_sources=$(python3 - "$current_sources" <<'PY'
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
PY
        ) || new_sources=""

        if [ -n "$new_sources" ]; then
            gsettings set org.gnome.desktop.input-sources sources "$new_sources"
            printf '%s\n' "Rime is present in the GNOME input-source list."
        else
            printf '%s\n' "Could not parse GNOME input sources; add Chinese (Rime) in Settings manually."
        fi
    else
        printf '%s\n' "No active GNOME settings session; add Chinese (Rime) in Settings manually."
    fi
else
    printf '%s\n' "gsettings/python3 unavailable; add Chinese (Rime) in Settings manually."
fi

printf '%s\n' "[5/5] Triggering Rime redeployment and restarting IBus..."
touch "$RIME_DIR"

if command -v ibus >/dev/null 2>&1; then
    if ! ibus restart; then
        printf '%s\n' "'ibus restart' failed; trying ibus-daemon -drx..."
        ibus-daemon -drx >/tmp/ibus-rime-restart.log 2>&1 &
    fi
else
    printf '%s\n' "IBus command not found. Log out and log back in to activate Rime."
fi

printf '\n%s\n' "Rime setup completed."
printf '%s\n' "Wait until the 'Rime is under maintenance' message disappears, then select Rime and type Chinese."
printf '%s\n' "Configuration directory: $RIME_DIR"
