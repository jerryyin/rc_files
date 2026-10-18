"""Prepare the current Linux account and install its Zsh plugins."""

from __future__ import annotations

import getpass
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

from context import Context


ZINIT_WAIT = re.compile(r"wait'[^']*'")


def bash_fallback(context: Context) -> None:
    path = context.home / '.bashrc'
    existing = path.read_text(encoding='utf-8') if path.exists() else ''
    marker = '# >>> rc_files: auto-exec zsh (chsh unavailable) >>>'
    if marker not in existing:
        context.save(path, existing + '\n' + marker + '\n'
                     '[ ! -f "$HOME/.config/zsh/interactive.sh" ] || . "$HOME/.config/zsh/interactive.sh"\n'
                     '# <<< rc_files: auto-exec zsh (chsh unavailable) <<<\n')
    print('chsh unavailable; interactive Bash will start Zsh through ~/.bashrc.')


def setup(context: Context) -> None:
    zsh = shutil.which('zsh')
    if not zsh:
        raise ValueError('Zsh is not installed')
    user = getpass.getuser()
    account = subprocess.check_output(['getent', 'passwd', user], text=True).strip()
    current = account.rsplit(':', 1)[-1]
    if current == zsh:
        print('SKIP Zsh login shell (already selected)')
    elif not shutil.which('sudo') or subprocess.run(
            ['sudo', '-n', 'chsh', '-s', zsh, user], capture_output=True).returncode:
        bash_fallback(context)
    source = (context.home / '.zshrc').read_text(encoding='utf-8')
    processed = ''.join(ZINIT_WAIT.sub('', line) if 'zinit ice' in line else line
                        for line in source.splitlines(keepends=True))
    with tempfile.TemporaryDirectory(prefix='rc-zsh-') as directory:
        path = Path(directory) / 'zshrc'
        path.write_text(processed, encoding='utf-8')
        context.run([zsh, '-c', 'source "$1"', 'rc-setup', str(path)])
