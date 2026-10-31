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
    signed_in = set(present)
    for login, token in tokens.items():
        if login in present and not update:
            continue
        # gh verifies each token online; an enterprise IP allow list can reject a valid token here.
        result = command([executable, 'auth', 'login', '--hostname', 'github.com',
                          '--git-protocol', 'https', '--with-token'], token)
        if result.returncode:
            print(f'SKIP gh {login}: GitHub rejected the vault token on this network')
            signed_in.discard(login)
        else:
            signed_in.add(login)
    if not signed_in.intersection(tokens):
        raise ValueError('GitHub CLI accepted none of the vault tokens')
    active = ACTIVE if ACTIVE in tokens else next(iter(tokens))
    if (update or not present) and active in signed_in:
        result = command([executable, 'auth', 'switch', '--hostname', 'github.com', '--user', active], '')
        if result.returncode:
            raise ValueError(f'GitHub CLI could not activate {active}')


def linux(tokens: dict[str, str]) -> None:
    login = ACTIVE if ACTIVE in tokens else next(iter(tokens))
    placeholders = {account: '__GH_TOKEN_' + str(index) + '__' for index, account in enumerate(tokens)}
    template = (Path(__file__).resolve().parents[1] / '.config/gh/hosts.yml.template').read_text()
    users = '\n'.join('        ' + account + ':\n            oauth_token: ' + placeholder
                      for account, placeholder in placeholders.items())
    template = template.replace('__GH_USERS__', users).replace('__GH_LOGIN__', login)
    template = template.replace('__GH_TOKEN__', placeholders[login])
    path = location('GH_CONFIG_DIR', Path.home() / '.config/gh') / 'hosts.yml'
    previous = path.read_text() if path.exists() else ''
    pattern = re.escape(template)
    for placeholder in placeholders.values():
        pattern = pattern.replace(re.escape(placeholder), r'[^\r\n]+')
    if previous and not re.fullmatch(pattern, previous) and os.environ.get('RC_SETUP_UPDATE') != '1':
        if os.environ.get('RC_CREDENTIALS_SCOPE', 'homelab') == 'homelab' and re.search(
                r'^\s*(?:user:\s*' + ACTIVE + r'\s*$|' + ACTIVE + r':)', previous, re.M):
            raise ValueError('GitHub configuration contains a work account; use a separate home or explicitly reseed with --update')
        print('SKIP gh: preserving local account state; credentials --package gh --update explicitly reseeds it')
        return
    desired = template
    for account, placeholder in placeholders.items():
        desired = desired.replace(placeholder, json.dumps(tokens[account]))
    write(path, desired)


def setup() -> None:
    if os.environ.get('RC_CREDENTIALS_SAVE') == '1':
        return
    personal = secret('GH_JERRYYIN_KEY_FILE', 'gh_token_jerryyin.txt')
    work = secret('GH_AMDENG_KEY_FILE', 'gh_token_amdeng.txt')
    tokens = {login: token for login, token in (('jerryyin', personal), (ACTIVE, work)) if token is not None}
    if not tokens:
        return
    if os.name == 'nt':
        if os.environ.get('RC_SETUP_REDIRECTED') == '1':
            print('SKIP gh: the Windows credential store belongs to the live account')
            return
        windows(tokens)
    else:
        linux(tokens)


if __name__ == '__main__':
    run(setup)
