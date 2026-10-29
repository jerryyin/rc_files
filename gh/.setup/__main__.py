"""Install a missing Linux GitHub CLI from its publisher's apt repository."""

import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import urllib.request

from system import apt, privileged


def setup() -> None:
    found = shutil.which('gh')
    launcher = Path(__file__).resolve().parents[1] / '.linux/.local/bin/gh'
    if found and Path(found).resolve() == launcher.resolve():
        search = os.pathsep.join(p for p in os.get_exec_path() if Path(p).resolve() != Path(found).parent.resolve())
        found = shutil.which('gh', path=search)
    if sys.platform != 'linux' or found:
        return
    if os.environ.get('RC_SETUP_INSTALL') == '0' or os.environ.get('RC_SETUP_REDIRECTED') == '1':
        raise ValueError('GitHub CLI is required; install it in the real account first')
    prefix = privileged()
    keyring = '/usr/share/keyrings/githubcli-archive-keyring.gpg'
    architecture = subprocess.check_output(['dpkg', '--print-architecture'], text=True).strip()
    with tempfile.TemporaryDirectory(prefix='rc-gh-') as temporary:
        key = Path(temporary) / 'github.gpg'
        urllib.request.urlretrieve('https://cli.github.com/packages/githubcli-archive-keyring.gpg', key)
        subprocess.run([*prefix, 'install', '-m', '644', str(key), keyring], check=True)
        source = Path(temporary) / 'github-cli.list'
        source.write_text(f'deb [arch={architecture} signed-by={keyring}] https://cli.github.com/packages stable main\n')
        subprocess.run([*prefix, 'install', '-m', '644', str(source), '/etc/apt/sources.list.d/github-cli.list'], check=True)
    apt(['update'])
    apt(['install', '-y', 'gh'])
    if not shutil.which('gh'):
        raise ValueError('GitHub CLI is still missing after installation')
    subprocess.run(['gh', '--version'], check=True)


if __name__ == '__main__':
    setup()
