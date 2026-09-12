#!/bin/sh
# Install familiar VS Code navigation shortcuts on Linux or from WSL.
set -eu
if ! command -v python3 >/dev/null 2>&1; then
    printf 'python3 is required. On Ubuntu: sudo apt install python3\n' >&2
    exit 1
fi
exec python3 - "$@" <<'PYTHON'
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

parser = argparse.ArgumentParser(description='Configure Ctrl+Left/Right as VS Code Back/Forward in the editor.')
parser.add_argument('--keybindings', type=Path, help='Explicit keybindings.json path (custom profile or portable install)')
parser.add_argument('--uninstall', action='store_true', help='Remove only the block added by this script')
args = parser.parse_args()
if os.geteuid() == 0:
    parser.error('Run as your normal desktop user, without sudo.')

BEGIN = '// >>> vscode_shortcuts_setup >>>'
END = '// <<< vscode_shortcuts_setup <<<'


def jsonc_mask(text):
    """Blank JSONC comments/trailing commas without changing character offsets."""
    chars = list(text)
    index = 0
    in_string = False
    while index < len(text):
        if text[index] == '"':
            in_string = not in_string
            index += 1
        elif in_string:
            index += 2 if text[index] == '\\' else 1
        elif text.startswith('//', index):
            end = text.find('\n', index)
            end = len(text) if end < 0 else end
            chars[index:end] = ' ' * (end - index)
            index = end
        elif text.startswith('/*', index):
            end = text.find('*/', index + 2)
            if end < 0:
                raise ValueError('Unterminated JSONC comment')
            end += 2
            chars[index:end] = ['\n' if c == '\n' else ' ' for c in text[index:end]]
            index = end
        else:
            index += 1
    masked = ''.join(chars)
    # Match strings first so commas inside strings remain untouched.
    masked = re.sub(r'"(?:\\.|[^"\\])*"|,(?=\s*[}\]])',
                    lambda match: ' ' if match.group() == ',' else match.group(), masked)
    return masked


def validate(text):
    masked = jsonc_mask(text)
    value = json.loads(masked)
    if not isinstance(value, list) or any(not isinstance(item, dict) for item in value):
        raise ValueError('Expected a JSONC array of keybinding objects')
    return masked


def target_path():
    if args.keybindings:
        return args.keybindings.expanduser().absolute()
    wsl = 'microsoft' in Path('/proc/sys/kernel/osrelease').read_text().lower()
    if not wsl:
        return Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home() / '.config'))) / 'Code/User/keybindings.json'
    powershell = shutil.which('powershell.exe')
    if not powershell:
        raise ValueError('WSL Windows interop is unavailable; use --keybindings with the Windows file path mounted in WSL')
    win_path = subprocess.check_output([
        powershell, '-NoProfile', '-NonInteractive', '-Command',
        '[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new(); [Environment]::GetFolderPath("ApplicationData")'
    ], text=True, encoding='utf-8').strip()
    if not win_path or '\n' in win_path:
        raise ValueError('Could not determine Windows AppData')
    mounted = subprocess.check_output(['wslpath', '-u', win_path], text=True).strip()
    return Path(mounted) / 'Code/User/keybindings.json'


try:
    target = target_path()
    if target.is_symlink() or (target.exists() and not target.is_file()):
        raise ValueError(f'Refusing non-regular file: {target}')
    existed = target.exists()
    original_bytes = target.read_bytes() if existed else b'[]\n'
    has_bom = original_bytes.startswith(b'\xef\xbb\xbf')
    original = original_bytes.decode('utf-8-sig')
    validate(original)
    block_pattern = re.compile(r'\r?\n[ \t]*' + re.escape(BEGIN) + r'\r?\n.*?'
                               + re.escape(END) + r'\r?\n', re.DOTALL)
    blocks = list(block_pattern.finditer(original))
    if original.count(BEGIN) != len(blocks) or original.count(END) != len(blocks) or len(blocks) > 1:
        raise ValueError('Ambiguous managed markers; inspect the file before modifying it')
    base = block_pattern.sub('', original)
    validate(base)
    if args.uninstall:
        updated = base
    else:
        masked = validate(base)
        closing = len(masked.rstrip()) - 1
        # Detect an existing trailing comma before JSONC normalization removes it.
        prefix = base[:closing]
        # A dummy object lets the JSONC parser tell us whether a comma is needed.
        try:
            validate(prefix + '{}'+ base[closing:])
            separator = ''
        except (ValueError, json.JSONDecodeError):
            separator = ','
        bindings = [
            {'key': 'ctrl+left', 'command': 'workbench.action.navigateBack', 'when': 'editorTextFocus'},
            {'key': 'ctrl+right', 'command': 'workbench.action.navigateForward', 'when': 'editorTextFocus'},
        ]
        content = ',\n'.join(json.dumps(binding, ensure_ascii=False, indent=2) for binding in bindings)
        block = '\n' + BEGIN + '\n' + separator + '\n' + content + '\n' + END + '\n'
        updated = prefix + block + base[closing:]
    validate(updated)
    if updated == original:
        print(f'Already configured; no changes: {target}')
        raise SystemExit(0)
    target.parent.mkdir(parents=True, exist_ok=True)
    if existed:
        descriptor, backup = tempfile.mkstemp(prefix=target.name + '.vscode_shortcuts_setup.backup.', dir=target.parent)
        os.close(descriptor)
        shutil.copy2(target, backup)
        print(f'Backup: {backup}')
    descriptor, temporary = tempfile.mkstemp(prefix=target.name + '.vscode_shortcuts_setup.', dir=target.parent)
    try:
        with os.fdopen(descriptor, 'wb') as handle:
            handle.write((b'\xef\xbb\xbf' if has_bom else b'') + updated.encode('utf-8'))
        if existed:
            shutil.copymode(target, temporary)
            if target.read_bytes() != original_bytes:
                raise ValueError('Keybindings changed during setup; retry after closing the settings editor')
        os.replace(temporary, target)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)
    print(f'{"Removed managed shortcuts" if args.uninstall else "Configured Ctrl+Left = Back; Ctrl+Right = Forward"}: {target}')
    print('VS Code reloads keybindings automatically. These bindings apply only when the code editor has focus.')
except (OSError, ValueError, subprocess.SubprocessError) as error:
    parser.exit(1, f'Configuration failed: {error}\n')
PYTHON
