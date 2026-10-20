"""Seed Linux GitHub tokens while preserving account state written by gh."""

import json
import os
from pathlib import Path
import re

from private import location, run, secret, write


def setup() -> None:
    if os.name == 'nt' or os.environ.get('RC_CREDENTIALS_SAVE') == '1':
        return  # Native Windows login uses the OS credential store.
    first = secret('GH_JERRYYIN_KEY_FILE', 'gh_token_jerryyin.txt')
    second = secret('GH_AMDENG_KEY_FILE', 'gh_token_amdeng.txt')
    if first is None or second is None:
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
