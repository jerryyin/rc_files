"""Install a wanted global npm CLI without changing npm's account settings."""

import json
import os
from pathlib import Path
import shutil
import ssl
import subprocess

from system import Package, install as install_system, persist_path, installed

def install(name: str, command: str) -> None:
    if os.name == 'nt' and os.environ.get('RC_SETUP_REDIRECTED') != '1':
        requirement = Package(command, npm=name)
        if not installed(requirement):
            install_system([requirement], allow=os.environ.get('RC_SETUP_INSTALL') != '0')
        return
    prefix = Path(os.environ['APPDATA']) / 'npm' if os.name == 'nt' else Path.home() / '.local'
    directory = prefix if os.name == 'nt' else prefix / 'bin'
    package = prefix / ('node_modules' if os.name == 'nt' else 'lib/node_modules') / name / 'package.json'
    existing = shutil.which(command)
    managed = existing and Path(existing).parent == directory and package.exists()
    if existing and (not managed or os.environ.get('RC_SETUP_UPDATE') != '1' or os.environ.get('RC_SETUP_INSTALL') == '0'):
        return
    if os.environ.get('RC_SETUP_INSTALL') == '0':
        raise ValueError(f'{command} is missing; --no-install cannot install it')
    npm = shutil.which('npm.cmd' if os.name == 'nt' else 'npm')
    if not npm:
        raise ValueError('Node and npm must be installed first')
    environment = dict(os.environ)
    bundle = ssl.get_default_verify_paths().cafile
    if bundle:
        environment.setdefault('NODE_EXTRA_CA_CERTS', bundle)
    subprocess.run([npm, 'install', '--global', '--prefix', str(prefix), name + '@latest'],
                   check=True, env=environment)
    if not package.exists() or not (directory / (command + '.cmd' if os.name == 'nt' else command)).exists():
        raise ValueError(f'npm did not install {command} into {prefix}')
    subprocess.run([str(directory / (command + '.cmd' if os.name == 'nt' else command)), '--version'],
                   check=True, env=environment)
    persist_path(directory)
    print(f'{name}: installed {json.loads(package.read_text())["version"]}')
