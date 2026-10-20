"""Maintain the vault-owned Artifactory block without replacing other netrc entries."""

import getpass
import os
from pathlib import Path
import re

from private import persist, run, secret, write


def setup() -> None:
    persist('.netrc')
    if os.name == 'nt' or os.environ.get('RC_CREDENTIALS_SAVE') == '1':
        return
    token = secret('ARTIFACTORY_KEY_FILE', 'atlartifactory_token.txt')
    if token is None:
        return
    host = os.environ.get('NETRC_HOST', 'atlartifactory.amd.com')
    login = os.environ.get('NETRC_LOGIN', getpass.getuser())
    if any(c.isspace() for c in host + login) or not host or not login:
        raise ValueError('Netrc host and login must be nonempty words')
    start, end = f'# >>> vault: {host} >>>', f'# <<< vault: {host} <<<'
    block = f'{start}\nmachine {host}\nlogin {login}\npassword {token}\n{end}\n'
    path = Path.home() / '.netrc'
    previous = path.read_text() if path.exists() else ''
    if previous.count(start) != previous.count(end) or previous.count(start) > 1:
        raise ValueError('Malformed managed netrc block; file preserved')
    if start in previous:
        desired = re.sub(re.escape(start) + r'.*?' + re.escape(end) + r'\n?', lambda _: block,
                         previous, flags=re.DOTALL)
    else:
        desired = previous + ('\n' if previous and not previous.endswith('\n') else '') + block
    write(path, desired)


if __name__ == '__main__':
    run(setup)
