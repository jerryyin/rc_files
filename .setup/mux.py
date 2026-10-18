"""Prepare tmux or native psmux from the shared tmux preferences."""

from __future__ import annotations

import json
from pathlib import Path
import re
import shutil
import subprocess
import uuid

from context import Context


SECTION = re.compile(r'# \[([^]]+)\]')
CONTINUATION = re.compile(r'\\\r?\n\s*')
PREFIX = re.compile(r'(?m)^set(?:-option)? -g prefix\s+([^\r\n]+)')
RESIZE = re.compile(r'''(?m)^set(?:-option)? -g @pane_resize\s+['"]?(\d+)''')
PLUGINS = re.compile(r'''(?m)^set(?:-option)? -g @plugin\s+['"]tmux-plugins/([^'"]+)['"]''')
SEPARATOR = re.compile(r'\s*\\;\s*')
RETAINED = re.compile(
    r'^unbind(-key)? |^bind(-key)? |^set -g prefix |'
    r'^(set|set-option|setw|set-window-option) -g '
    r'(status-right|status-style|status-keys|mode-keys|mouse|status-justify|status|'
    r'status-left-style|message-command-style|status-right-style|message-style|'
    r'pane-active-border-style|pane-border-style|status-right-length|status-left-length|'
    r'window-status-activity-style|window-status-separator|status-left|'
    r'window-status-format|window-status-current-format) ')


def render(repo: Path, home: Path) -> str:
    sections: dict[str, list[str]] = {}
    section = ''
    for line in (repo / 'tmux/.windows/.tmux/psmux-compat.conf').read_text(encoding='utf-8').splitlines():
        header = SECTION.fullmatch(line)
        if header:
            section = header[1]
            sections[section] = []
        elif section and line and not line.startswith('#'):
            sections[section].append(line)
    lines = ['# Generated from rc_files/tmux/.tmux.conf; native PowerShell panes.']
    lines.extend(sections['navigation'])
    source = CONTINUATION.sub(' ', (repo / 'tmux/.tmux.conf').read_text(encoding='utf-8'))
    prefix = PREFIX.search(source)
    if prefix is None:
        raise ValueError('Shared tmux configuration has no prefix')
    for line in source.splitlines():
        if RETAINED.match(line):
            line = line.replace('set prefix None', 'set -g prefix None').replace('set key-table off', 'set -g key-table off')
            line = line.replace('set -u prefix', 'set -g prefix ' + prefix[1].strip())
            line = line.replace('set -u key-table', 'set -g key-table root').replace('~/.tmux.conf', '~/.psmux.conf')
            lines.append(SEPARATOR.sub(r' \; ', line).replace('$wg_is_keys_off', ''))
    resize = RESIZE.search(source)
    names = ['native', *PLUGINS.findall(source)]
    for name in names:
        for line in sections.get(name, []):
            lines.append(line.replace('%PANE_RESIZE%', resize[1] if resize else '5')
                         .replace('%MUX_SCRIPT%', (repo / 'tmux/.windows/.tmux/mux.ps1').as_posix())
                         .replace('%PLUGIN_ROOT%', (home / '.psmux/plugins').as_posix()))
    return '\n'.join(lines) + '\n'


def windows_plugins(context: Context) -> None:
    source = (context.repo / 'tmux/.tmux.conf').read_text(encoding='utf-8')
    declared = PLUGINS.findall(source)
    required = {
        'tpm': ('ppm', ['ppm.ps1', 'scripts/install_plugins.ps1', 'scripts/update_plugins.ps1', 'scripts/clean_plugins.ps1']),
        'tmux-resurrect': ('psmux-resurrect', ['psmux-resurrect.ps1', 'scripts/save.ps1', 'scripts/restore.ps1']),
    }
    plugins = [required[name] for name in declared if name in required]
    root = context.home / '.psmux/plugins'
    if not context.update and all((root / name / item).is_file() for name, files in plugins for item in files):
        print('SKIP psmux plugins (installed)')
        return
    cache = context.home / '.psmux/plugin-source'
    url = 'https://github.com/psmux/psmux-plugins.git'
    if not cache.exists():
        context.run(['git', 'clone', '--depth', '1', url, str(cache)])
    elif context.update:
        context.run(['git', '-C', str(cache), 'pull', '--ff-only'])
    for name, files in plugins:
        target = root / name
        shutil.copytree(cache / name, target, dirs_exist_ok=True)
        (target / '.monorepo.json').write_text(json.dumps({
            'monorepo': 'psmux/psmux-plugins', 'org': 'psmux-plugins', 'name': name,
            'url': url, 'branch': None,
        }), encoding='utf-8')
        if not all((target / item).is_file() for item in files):
            raise ValueError(f'Incomplete psmux plugin: {target}')


def linux_plugins(context: Context) -> None:
    tmux = shutil.which('tmux')
    if not tmux:
        raise ValueError('tmux is not installed')
    tpm = context.home / '.tmux/plugins/tpm'
    if not tpm.is_dir():
        context.run(['git', 'clone', 'https://github.com/tmux-plugins/tpm', str(tpm)])
    elif context.update:
        context.run(['git', '-C', str(tpm), 'pull', '--ff-only'])
    environment = context.environment()
    environment.pop('TMUX', None)
    environment.pop('TMUX_PANE', None)
    server = [tmux, '-L', 'rc-setup-' + uuid.uuid4().hex]
    try:
        context.run([*server, '-f', str(context.home / '.tmux.conf'), 'new-session', '-d',
                     '-s', 'plugins', 'cat'], environment=environment)
        identity = subprocess.check_output([*server, 'display-message', '-p', '#{socket_path},#{pid},0'],
                                           env=environment, text=True).strip()
        environment['TMUX'] = identity
        context.run([str(tpm / 'bin/install_plugins')], environment=environment)
        if context.update:
            context.run([str(tpm / 'bin/update_plugins'), 'all'], environment=environment)
    finally:
        subprocess.run([*server, 'kill-server'], env=environment, capture_output=True)
    if context.home == Path.home().resolve():
        live = context.environment()
        if subprocess.run([tmux, 'has-session'], env=live, capture_output=True).returncode == 0:
            context.run([tmux, 'source-file', str(context.home / '.tmux.conf')], environment=live)


def setup(context: Context, *, render_only: bool = False) -> None:
    if context.platform == 'windows':
        context.save(context.home / '.psmux/generated.conf', render(context.repo, context.home))
        if not render_only:
            windows_plugins(context)
    elif not render_only:
        linux_plugins(context)
