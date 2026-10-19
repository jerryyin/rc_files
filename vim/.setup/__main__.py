"""Install the shared Vim plugins and CoC extensions on either platform."""

from __future__ import annotations

import json
import os
from pathlib import Path
import shutil
import ssl
import subprocess


def executable() -> Path | None:
    found = shutil.which('vim')
    if found and not (os.name == 'nt' and 'git' in {part.lower() for part in Path(found).parts}):
        return Path(found)
    return None


def setup(home: Path) -> None:
    vim_exe = executable()
    if vim_exe is None:
        raise ValueError('Native Vim is not on PATH')
    (home / '.vim').mkdir(parents=True, exist_ok=True)
    subprocess.run([str(vim_exe), '-n', '-E', '-s', '-V1' + str(home / '.vim/plugin-install.log'),
                    '-u', 'NONE', '-S', str(Path(__file__).with_name('vim-plugins.vim'))], check=True)
    extensions(home)


def extensions(home: Path) -> None:
    npm = shutil.which('npm.cmd' if os.name == 'nt' else 'npm')
    if not npm:
        raise ValueError('npm is required to install CoC extensions')
    package_root = Path(__file__).resolve().parents[1]
    choices = json.loads((package_root / '.vim/coc-extensions.json').read_text(encoding='utf-8'))
    directory = home / '.config/coc/extensions'
    package = directory / 'package.json'
    if package.exists():
        choices.extend(json.loads(package.read_text(encoding='utf-8-sig')).get('dependencies', {}))
    directory.mkdir(parents=True, exist_ok=True)
    print('CoC extensions: checking latest versions (existing choices are retained).', flush=True)
    environment = dict(os.environ)
    if not environment.get('NODE_EXTRA_CA_CERTS'):
        bundle = ssl.get_default_verify_paths().cafile
        if bundle:
            environment['NODE_EXTRA_CA_CERTS'] = bundle
    subprocess.run([npm, 'install', '--save', '--no-package-lock',
                    *[name + '@latest' for name in dict.fromkeys(choices)]],
                   cwd=directory, env=environment, check=True)


if __name__ == '__main__':
    setup(Path.home())
