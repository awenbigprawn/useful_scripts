#!/bin/sh
# Configure readable Bash prompt and ls directory colors for Ubuntu/WSL.
set -eu

SCRIPT_NAME=$(basename "$0")

usage() {
    printf 'Usage: sh %s [--uninstall]\n' "$SCRIPT_NAME"
    printf 'Run as your normal Ubuntu user, without sudo. Reopen Bash or run: . ~/.bashrc\n'
}

mode=install
case "${1:-}" in
    '') ;;
    --uninstall) mode=uninstall ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
esac
if [ "$#" -gt 1 ]; then usage >&2; exit 2; fi

: "${HOME:?HOME must be set}"
rc="$HOME/.bashrc"
if [ -L "$rc" ]; then
    printf 'Refusing to replace a symlink: %s\n' "$rc" >&2
    exit 1
fi
if [ -e "$rc" ] && [ ! -f "$rc" ]; then
    printf 'Not a regular file: %s\n' "$rc" >&2
    exit 1
fi
if [ "$mode" = uninstall ] && [ ! -e "$rc" ]; then
    printf 'No configuration to remove.\n'
    exit 0
fi

begin='# >>> ubuntu_colors_setup >>>'
end='# <<< ubuntu_colors_setup <<<'
# Recognize the previous script's markers when upgrading or uninstalling.
legacy_begin='# >>> ubuntu-readable-colors >>>'
legacy_end='# <<< ubuntu-readable-colors <<<'
temp=$(mktemp "$HOME/.bashrc.ubuntu_colors_setup.XXXXXXXX")
trap 'rm -f -- "$temp"' 0

# Remove only managed blocks; retain all unrelated configuration.
if [ -f "$rc" ]; then
    awk -v start="$begin" -v finish="$end" \
        -v old_start="$legacy_begin" -v old_finish="$legacy_end" '
        $0 == start || $0 == old_start {
            if (inside) exit 2
            inside=1
            expected=($0 == start ? finish : old_finish)
            next
        }
        $0 == finish || $0 == old_finish {
            if (!inside || $0 != expected) exit 2
            inside=0
            next
        }
        !inside { print }
        END { if (inside) exit 2 }
    ' "$rc" > "$temp"
fi

if [ "$mode" = install ]; then
    cat >> "$temp" <<'UBUNTU_COLORS_CONFIG'
# >>> ubuntu_colors_setup >>>
# Username: green. Hostname, path and ls directories: light sky blue (#87CEFA).
case $- in
    *i*)
        if [ "${TERM:-dumb}" != dumb ]; then
            PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\[\033[0;38;2;135;206;250m\]\h:\w\[\033[0m\]\$ '
            case "$TERM" in
                xterm*|rxvt*) PS1="\[\e]0;\u@\h: \w\a\]$PS1" ;;
            esac
            # Preserve other file colors and avoid duplicate di entries.
            LS_COLORS="$(printf '%s' "${LS_COLORS:-}" | sed -E 's/(^|:)di=[^:]*//g; s/:+$//')"
            export LS_COLORS="${LS_COLORS:+${LS_COLORS}:}di=0;38;2;135;206;250"
            alias ls='ls --color=auto'
        fi
        ;;
esac
# <<< ubuntu_colors_setup <<<
UBUNTU_COLORS_CONFIG
fi

# The installer runs with sh; its target is still the user's Bash configuration.
bash -n "$temp"
if [ -f "$rc" ] && cmp -s "$rc" "$temp"; then
    printf '%s: already configured; no changes made.\n' "$SCRIPT_NAME"
    exit 0
fi
if [ -f "$rc" ]; then
    backup=$(mktemp "$HOME/.bashrc.ubuntu_colors_setup.backup.XXXXXXXX")
    cp -p -- "$rc" "$backup"
    chmod --reference="$rc" "$temp"
    printf 'Backup: %s\n' "$backup"
fi
mv -- "$temp" "$rc"
if [ "$mode" = install ]; then
    printf '%s: installed. Apply in your current Ubuntu Bash shell: . ~/.bashrc\n' "$SCRIPT_NAME"
else
    printf '%s: removed managed colors. Start a new Bash session to use your previous settings.\n' "$SCRIPT_NAME"
fi
