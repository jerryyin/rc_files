"""Install the shared Vim plugins and CoC extensions on either platform."""

from __future__ import annotations

import json
import os
from pathlib import Path
import shutil

from context import Context


def executable() -> Path | None:
    found = shutil.which('vim')
    if os.name != 'nt':
        return Path(found) if found else None
    if found and 'git' not in {part.lower() for part in Path(found).parts}:
        return Path(found)
    for name, suffix in (('LOCALAPPDATA', 'Programs/Vim'), ('ProgramFiles', 'Vim'),
                         ('ProgramFiles(x86)', 'Vim')):
        if os.environ.get(name):
            root = Path(os.environ[name]) / suffix
            candidates = sorted([*root.glob('vim.exe'), *root.glob('vim*/vim.exe')], reverse=True)
            if candidates:
                return candidates[0]
    return None


def setup(context: Context, *, vim_exe: Path | None = None) -> None:
    vim_exe = vim_exe or executable()
    if vim_exe is None:
        raise ValueError('Vim is not installed')
    (context.home / '.vim').mkdir(parents=True, exist_ok=True)
    context.run([str(vim_exe), '-n', '-E', '-s', '-V1' + str(context.home / '.vim/plugin-install.log'),
                 '-u', 'NONE', '-S', str(Path(__file__).with_name('vim-plugins.vim'))])
    extensions(context)


def extensions(context: Context) -> None:
    npm = shutil.which('npm.cmd' if context.platform == 'windows' else 'npm')
    if not npm:
        raise ValueError('npm is required to install CoC extensions')
    choices = json.loads((context.repo / 'vim/.vim/coc-extensions.json').read_text(encoding='utf-8'))
    directory = context.home / '.config/coc/extensions'
    package = directory / 'package.json'
    if package.exists():
        choices.extend(json.loads(package.read_text(encoding='utf-8-sig')).get('dependencies', {}))
    directory.mkdir(parents=True, exist_ok=True)
    print('CoC extensions: checking latest versions (existing choices are retained).', flush=True)
    context.run([npm, 'install', '--save', '--no-package-lock',
                 *[name + '@latest' for name in dict.fromkeys(choices)]], cwd=directory)
