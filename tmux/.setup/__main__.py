"""Bootstrap plugin managers and run them against the installed native rc files."""

from __future__ import annotations

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import uuid


def windows_plugins(home: Path, update: bool) -> None:
    psmux = shutil.which('psmux')
    pwsh = shutil.which('pwsh')
    if not psmux or not pwsh:
        raise ValueError('psmux and PowerShell 7 are required to install native mux plugins')
    manager = home / '.psmux/plugins/ppm'
    if update or not (manager / 'ppm.ps1').is_file():
        cache = home / '.psmux/plugin-source'
        if not cache.exists():
            subprocess.run(['git', 'clone', '--depth', '1', 'https://github.com/psmux/psmux-plugins.git', str(cache)], check=True)
        elif update:
            subprocess.run(['git', '-C', str(cache), 'pull', '--ff-only'], check=True)
        shutil.copytree(cache / 'ppm', manager, dirs_exist_ok=True)
    environment = {key: value for key, value in os.environ.items()
                   if not key.startswith(('PSMUX_', 'TMUX'))}
    with tempfile.TemporaryDirectory(prefix='rc-psmux-') as directory:
        environment.update(PSMUX_DATA_DIR=directory, PSMUX_SESSION_NAME='plugins',
                           PSMUX_TARGET_SESSION='plugins', PSMUX_SESSION='plugins', PSMUX_NO_WARM='1')
        try:
            subprocess.run([psmux, '-f', str(home / '.psmux.conf'), 'new-session', '-d',
                            '-s', 'plugins', '--', pwsh, '-NoProfile', '-Command', 'Start-Sleep 600'],
                           env=environment, check=True)
            command = [pwsh, '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
                       str(Path(__file__).with_name('psmux-plugins.ps1'))]
            if update:
                command.append('-Update')
            subprocess.run(command, env=environment, check=True)
        finally:
            subprocess.run([psmux, 'kill-server'], env=environment, capture_output=True)


def linux_plugins(home: Path, update: bool) -> None:
    tmux = shutil.which('tmux')
    if not tmux:
        raise ValueError('tmux is not installed')
    tpm = home / '.tmux/plugins/tpm'
    if not tpm.is_dir():
        subprocess.run(['git', 'clone', 'https://github.com/tmux-plugins/tpm', str(tpm)], check=True)
    elif update:
        subprocess.run(['git', '-C', str(tpm), 'pull', '--ff-only'], check=True)
    environment = dict(os.environ)
    environment.pop('TMUX', None)
    environment.pop('TMUX_PANE', None)
    server = [tmux, '-L', 'rc-setup-' + uuid.uuid4().hex]
    try:
        subprocess.run([*server, '-f', str(home / '.tmux.conf'), 'new-session', '-d',
                        '-s', 'plugins', 'cat'], env=environment, check=True)
        identity = subprocess.check_output([*server, 'display-message', '-p', '#{socket_path},#{pid},0'],
                                           env=environment, text=True).strip()
        environment['TMUX'] = identity
        subprocess.run([str(tpm / 'bin/install_plugins')], env=environment, check=True)
        if update:
            subprocess.run([str(tpm / 'bin/update_plugins'), 'all'], env=environment, check=True)
    finally:
        subprocess.run([*server, 'kill-server'], env=environment, capture_output=True)
    if home == Path.home().resolve() and os.environ.get('RC_SETUP_REDIRECTED') != '1':
        live = dict(os.environ)
        if subprocess.run([tmux, 'has-session'], env=live, capture_output=True).returncode == 0:
            subprocess.run([tmux, 'source-file', str(home / '.tmux.conf')], env=live, check=True)


def setup(home: Path, update: bool) -> None:
    if os.name == 'nt':
        windows_plugins(home, update)
    else:
        linux_plugins(home, update)


if __name__ == '__main__':
    setup(Path.home(), os.environ.get('RC_SETUP_UPDATE') == '1')
