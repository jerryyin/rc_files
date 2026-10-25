"""Activate local SSH keys and link the private host inventory."""

import os
from pathlib import Path

from keys import load_agent, prepare_keys, protect
from private import run


def setup() -> None:
    if os.environ.get('RC_CREDENTIALS_SAVE') == '1':
        return
    home = Path.home()
    explicit = os.environ.get('RC_CREDENTIALS_SOURCE', '')
    root = os.environ.get('RC_CREDENTIALS_ROOT', '')
    source = Path(explicit) if explicit else Path(root) / '.ssh' if root else None
    if not explicit and source is not None and not source.is_dir():
        source = None
    directory = home / '.ssh'
    keys = prepare_keys(directory, source)
    vault = Path(os.environ.get('RC_CREDENTIALS_VAULT', str(home / 'vault')))
    hosts = vault / 'ssh/config'
    target = directory / 'private.conf'
    linked = target.is_symlink() and target.resolve() == hosts.resolve()
    if os.path.lexists(target) and not linked:
        raise ValueError('Reconcile the existing SSH private configuration before linking it')
    if os.name == 'nt' and os.environ.get('RC_SETUP_REDIRECTED') != '1' and not linked:
        raise ValueError('Run SSH setup first to prepare the Windows private configuration link')
    if hosts.exists() and not hosts.is_file():
        raise ValueError('SSH host inventory must be a file')
    if hosts.is_file():
        protect([hosts])
    load_agent(keys)
    if not linked:
        target.symlink_to(hosts.resolve())


if __name__ == '__main__':
    run(setup)
