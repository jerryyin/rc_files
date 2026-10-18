"""Install the shared Vim plugins and CoC extensions on either platform."""

from __future__ import annotations

import json
import os
from pathlib import Path
import re
import shutil
import sys

from context import Context


PYTHON_DLL = re.compile(r'python[0-9]{2,}\.dll')


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


def configure(context: Context, git_bash: Path | None, python_root: Path | None) -> None:
    (context.home / '.vim/session').mkdir(parents=True, exist_ok=True)
    if context.platform != 'windows':
        return
    if git_bash is None:
        git = shutil.which('git')
        if not git:
            raise ValueError('Git for Windows is required by native Vim')
        git_bash = Path(git).parent.parent / 'bin/bash.exe'
        if not git_bash.is_file():
            raise ValueError('Git for Windows Bash could not be located; use --git-bash')
    python_root = python_root or Path(sys.base_prefix)
    dlls = sorted(path for path in python_root.glob('python*.dll')
                  if PYTHON_DLL.fullmatch(path.name))
    if not dlls:
        raise ValueError(f'The native Python runtime DLL could not be found: {python_root}')
    context.save_json(context.home / '.vim/machine-paths.json', {
        'gitBash': git_bash.as_posix(), 'pythonRoot': python_root.as_posix(),
        'pythonDll': dlls[0].as_posix(), 'vimrc': (context.repo / 'vim/.vimrc').as_posix(),
    })


def extensions(context: Context) -> None:
    npm = shutil.which('npm.cmd' if context.platform == 'windows' else 'npm')
    if not npm:
        raise ValueError('npm is required to install CoC extensions')
    choices = json.loads((context.repo / 'vim/.vim/coc-extensions.json').read_text(encoding='utf-8'))
    directory = context.home / '.config/coc/extensions'
    package_path = directory / 'package.json'
    package = json.loads(package_path.read_text(encoding='utf-8-sig')) if package_path.exists() else {}
    dependencies = package.setdefault('dependencies', {})
    for name in choices:
        dependencies.setdefault(name, 'latest')
    for name in dependencies:
        dependencies[name] = 'latest'
    context.save_json(package_path, package)
    pending = any(not (directory / 'node_modules' / name / 'package.json').is_file()
                  for name in dependencies)
    print('CoC extensions: checking latest versions (existing choices are retained).', flush=True)
    context.run([npm, 'install' if pending else 'update', '--no-save', '--no-package-lock'], cwd=directory)


def setup(context: Context, *, vim_exe: Path | None = None, git_bash: Path | None = None,
          python_root: Path | None = None, configure_only: bool = False) -> None:
    configure(context, git_bash, python_root)
    if configure_only:
        return
    vim_exe = vim_exe or executable()
    if vim_exe is None:
        raise ValueError('Vim is not installed')
    plug = context.home / '.vim/autoload/plug.vim'
    if context.update or not plug.is_file():
        context.download('https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim', plug)
    environment = context.environment()
    environment.update(RC_SETUP_REPO=str(context.repo), RC_SETUP_HOME=str(context.home),
                       RC_SETUP_UPDATE=str(int(context.update)))
    context.run([str(vim_exe), '-n', '-E', '-s', '-V1' + str(context.home / '.vim/plugin-install.log'),
                 '-u', 'NONE', '-S', str(Path(__file__).with_name('vim-plugins.vim'))],
                environment=environment)
    extensions(context)
