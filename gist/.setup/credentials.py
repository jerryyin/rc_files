"""Restore gist-paste's token from the personal GitHub vault entry."""

import os
from pathlib import Path

from private import location, run, secret, write


def setup() -> None:
    if os.name == 'nt' or os.environ.get('RC_CREDENTIALS_SAVE') == '1':
        return
    variable = 'GIST_KEY_FILE' if 'GIST_KEY_FILE' in os.environ else 'GH_JERRYYIN_KEY_FILE'
    token = secret(variable, 'gh_token_jerryyin.txt')
    if token is not None:
        write(location('GIST_CONFIG', Path.home() / '.gist'), token + '\n')


if __name__ == '__main__':
    run(setup)
