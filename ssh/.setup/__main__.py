"""Prepare the local SSH client without accessing private storage."""

import os
from pathlib import Path
import subprocess

from keys import protect


if __name__ == '__main__':
    directory = Path.home() / '.ssh'
    if directory.is_dir():
        protect([directory])
    if os.name == 'nt' and os.environ.get('RC_SETUP_REDIRECTED') != '1':
        arguments = ['powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass',
                     '-File', str(Path(__file__).with_name('windows.ps1')), '-PrepareAgent',
                     '-VaultPath', os.environ.get('RC_CREDENTIALS_VAULT', str(Path.home() / 'vault'))]
        if os.environ.get('RC_SETUP_INSTALL') == '0':
            arguments.append('-ReadyOnly')
        subprocess.run(arguments, check=True)
