"""Bootstrap plugin managers and run them against the installed native rc files."""

from __future__ import annotations

from pathlib import Path
import shutil
import subprocess
import tempfile
import uuid

from context import Context


def windows_plugins(context: Context) -> None:
    psmux = shutil.which('psmux')
    pwsh = shutil.which('pwsh')
    if not psmux or not pwsh:
        raise ValueError('psmux and PowerShell 7 are required to install native mux plugins')
    manager = context.home / '.psmux/plugins/ppm'
    if context.update or not (manager / 'ppm.ps1').is_file():
        cache = context.home / '.psmux/plugin-source'
        if not cache.exists():
            context.run(['git', 'clone', '--depth', '1', 'https://github.com/psmux/psmux-plugins.git', str(cache)])
        elif context.update:
            context.run(['git', '-C', str(cache), 'pull', '--ff-only'])
        shutil.copytree(cache / 'ppm', manager, dirs_exist_ok=True)
    environment = {key: value for key, value in context.environment().items()
                   if not key.startswith(('PSMUX_', 'TMUX'))}
    with tempfile.TemporaryDirectory(prefix='rc-psmux-') as directory:
        environment.update(PSMUX_DATA_DIR=directory, PSMUX_SESSION_NAME='plugins',
                           PSMUX_TARGET_SESSION='plugins', PSMUX_SESSION='plugins', PSMUX_NO_WARM='1')
        try:
            context.run([psmux, '-f', str(context.home / '.psmux.conf'), 'new-session', '-d',
                         '-s', 'plugins', '--', pwsh, '-NoProfile', '-Command', 'Start-Sleep 600'],
                        environment=environment)
            command = [pwsh, '-NoProfile', '-File', str(Path(__file__).with_name('psmux-plugins.ps1'))]
            if context.update:
                command.append('-Update')
            context.run(command, environment=environment)
        finally:
            subprocess.run([psmux, 'kill-server'], env=environment, capture_output=True)


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


def setup(context: Context) -> None:
    if context.platform == 'windows':
        windows_plugins(context)
    else:
        linux_plugins(context)
