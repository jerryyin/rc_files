"""Ensure a supported Node LTS and npm on Linux; WinGet supplies Windows Node."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import urllib.request

from system import apt, privileged
from requirements import MINIMUM


def version() -> tuple[int, ...]:
    if not shutil.which('node'):
        return ()
    return tuple(map(int, subprocess.check_output(['node', '--version'], text=True).strip().lstrip('v').split('.')))


def setup() -> None:
    if version() >= MINIMUM and shutil.which('npm.cmd' if os.name == 'nt' else 'npm'):
        return
    if os.environ.get('RC_SETUP_INSTALL') == '0' or os.environ.get('RC_SETUP_REDIRECTED') == '1':
        raise ValueError('Node >=22.19 and npm are required; install them in the real account first')
    if sys.platform != 'linux':
        raise ValueError('Node and npm are missing after native package installation')
    with urllib.request.urlopen('https://nodejs.org/dist/index.json') as response:
        releases = json.load(response)
    major = next(int(release['version'].lstrip('v').split('.')[0]) for release in releases if release['lts'])
    prefix = privileged()
    architecture = subprocess.check_output(['dpkg', '--print-architecture'], text=True).strip()
    with tempfile.TemporaryDirectory(prefix='rc-node-') as temporary:
        key = Path(temporary) / 'nodesource.asc'
        urllib.request.urlretrieve('https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key', key)
        subprocess.run([*prefix, 'gpg', '--batch', '--yes', '--dearmor', '-o',
                        '/usr/share/keyrings/nodesource.gpg', str(key)], check=True)
        subprocess.run([*prefix, 'chmod', '644', '/usr/share/keyrings/nodesource.gpg'], check=True)
        source = Path(temporary) / 'nodesource.sources'
        source.write_text(f'Types: deb\nURIs: https://deb.nodesource.com/node_{major}.x\nSuites: nodistro\n'
                          f'Components: main\nArchitectures: {architecture}\nSigned-By: /usr/share/keyrings/nodesource.gpg\n')
        legacy = Path('/etc/apt/sources.list.d/nodesource.list')
        if legacy.exists():
            if 'deb.nodesource.com/' not in legacy.read_text():
                raise ValueError(f'Unrecognized repository settings: {legacy}')
            subprocess.run([*prefix, 'rm', '--', str(legacy)], check=True)
        subprocess.run([*prefix, 'install', '-m', '644', str(source), '/etc/apt/sources.list.d/nodesource.sources'], check=True)
    apt(['update'])
    apt(['install', '-y', 'nodejs'])
    if version() < (major, 0, 0) or not shutil.which('npm'):
        raise ValueError(f'Node LTS {major} and npm are still missing after installation')


if __name__ == '__main__':
    setup()
