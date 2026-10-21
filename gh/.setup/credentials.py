"""Seed GitHub tokens from the vault while preserving account state written by gh."""

import json
import os
from pathlib import Path
import re
import shutil

from private import command, location, run, secret, write

ACTIVE = 'zhuoryin_amdeng'


def windows(tokens: dict[str, str]) -> None:
    """Store vault tokens in gh's Windows credential store, keeping existing accounts."""
    executable = shutil.which('gh')
    if not executable:
        raise ValueError('Install GitHub CLI before applying its credentials')
    status = command([executable, 'auth', 'status', '--hostname', 'github.com', '--json', 'hosts'], '')
    try:
        accounts = json.loads(status.stdout).get('hosts', {}).get('github.com', [])
    except (json.JSONDecodeError, AttributeError):
        accounts = []
    present = {account.get('login') for account in accounts if account.get('state') == 'success'}
    update = os.environ.get('RC_SETUP_UPDATE') == '1'
    for login, token in tokens.items():
        if login in present and not update:
            continue
        result = command([executable, 'auth', 'login', '--hostname', 'github.com',
                          '--git-protocol', 'https', '--with-token'], token)
        if result.returncode:
            raise ValueError(f'GitHub CLI rejected the vault token for {login}')
    if update or not present:
        result = command([executable, 'auth', 'switch', '--hostname', 'github.com', '--user', ACTIVE], '')
        if result.returncode:
            raise ValueError(f'GitHub CLI could not activate {ACTIVE}')


def setup() -> None:
    if os.environ.get('RC_CREDENTIALS_SAVE') == '1':
        return
    first = secret('GH_JERRYYIN_KEY_FILE', 'gh_token_jerryyin.txt')
    second = secret('GH_AMDENG_KEY_FILE', 'gh_token_amdeng.txt')
    if first is None or second is None:
        return
    if os.name == 'nt':
        if os.environ.get('RC_SETUP_REDIRECTED') == '1':
            print('SKIP gh: the Windows credential store belongs to the live account')
            return
        windows({'jerryyin': first, 'zhuoryin_amdeng': second})
        return
    template = (Path(__file__).resolve().parents[1] / '.config/gh/hosts.yml.template').read_text()
    path = location('GH_CONFIG_DIR', Path.home() / '.config/gh') / 'hosts.yml'
    previous = path.read_text() if path.exists() else ''
    pattern = re.escape(template)
    for name in ('__GH_TOKEN_JERRYYIN__', '__GH_TOKEN_AMDENG__'):
        pattern = pattern.replace(re.escape(name), r'[^\r\n]+')
    if previous and not re.fullmatch(pattern, previous) and os.environ.get('RC_SETUP_UPDATE') != '1':
        print('SKIP gh: preserving local account state; credentials --package gh --update explicitly reseeds it')
        return
    desired = template.replace('__GH_TOKEN_JERRYYIN__', json.dumps(first)).replace('__GH_TOKEN_AMDENG__', json.dumps(second))
    write(path, desired)


if __name__ == '__main__':
    run(setup)
