"""Load Zsh's declared plugins eagerly during Linux setup."""

import os
from pathlib import Path
import shutil
import subprocess
import sys

if sys.platform == 'linux':
    import pwd


def login_shell() -> None:
    if os.environ.get('RC_SETUP_REDIRECTED') == '1':
        return
    zsh = shutil.which('zsh')
    user = pwd.getpwuid(os.getuid())
    if user.pw_shell == zsh:
        return
    prefix = [] if os.geteuid() == 0 else ['sudo', '-n']
    result = subprocess.run([*prefix, 'chsh', '-s', zsh, user.pw_name], capture_output=True)
    if result.returncode == 0:
        return
    bashrc = Path.home() / '.bashrc'
    content = bashrc.read_text() if bashrc.exists() else ''
    marker = '# >>> rc_files: auto-exec zsh (chsh unavailable) >>>'
    if marker not in content:
        with bashrc.open('a') as stream:
            stream.write('\n' + marker + '\n'
                         '[ ! -f "$HOME/.config/zsh/interactive.sh" ] || . "$HOME/.config/zsh/interactive.sh"\n'
                         '# <<< rc_files: auto-exec zsh (chsh unavailable) <<<\n')


if __name__ == '__main__' and sys.platform == 'linux':
    subprocess.run(['zsh', '-c', 'source "$HOME/.zshrc"'], check=True)
    login_shell()
