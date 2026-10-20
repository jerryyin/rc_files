"""Restore the managed registry credential without replacing Docker settings."""

import base64
import binascii
import json
import os
from pathlib import Path
import shutil

from private import command, location, read_json, run, secret, write


def helper_login(helper: str, registry: str, username: str, password: str, directory: Path) -> None:
    executable = shutil.which('docker-credential-' + helper)
    if executable:
        stored = command([executable, 'get'], registry + '\n')
        try:
            credential = json.loads(stored.stdout)
        except json.JSONDecodeError:
            credential = None
        if stored.returncode == 0 and isinstance(credential, dict) and credential.get('Username') == username and credential.get('Secret') == password:
            return
    docker = shutil.which('docker')
    if not docker:
        print('SKIP Docker: install its CLI and credential helper, then rerun credentials')
        return
    result = command([docker, '--config', str(directory), 'login', registry,
                      '--username', username, '--password-stdin'], password + '\n')
    if result.returncode:
        raise ValueError('Docker login failed; helper diagnostics were suppressed')


def setup() -> None:
    if os.environ.get('RC_CREDENTIALS_SAVE') == '1':
        return
    auth = secret('DOCKER_AUTH_FILE', 'docker_mkmhub_auth.txt')
    if auth is None:
        return
    try:
        decoded = base64.b64decode(auth, validate=True).decode('utf-8')
    except (binascii.Error, UnicodeError):
        raise ValueError('Docker vault entry must be base64 username:password') from None
    username, separator, password = decoded.partition(':')
    if not separator or not username or not password or any(c in decoded for c in '\r\n\x00'):
        raise ValueError('Docker vault entry must be base64 username:password')
    directory = location('DOCKER_CONFIG', Path.home() / '.docker')
    path = directory / 'config.json'
    config = read_json(path)
    registry = os.environ.get('DOCKER_REGISTRY', 'mkmhub.amd.com')
    helpers = config.get('credHelpers', {})
    if not isinstance(helpers, dict):
        raise ValueError('Docker credHelpers must be an object')
    helper = helpers.get(registry) or config.get('credsStore')
    if helper:
        if not isinstance(helper, str) or not all(c.isalnum() or c in '-_.' for c in helper):
            raise ValueError('Invalid Docker credential helper name')
        helper_login(helper, registry, username, password, directory)
        return
    auths = config.setdefault('auths', {})
    if not isinstance(auths, dict) or not isinstance(auths.get(registry, {}), dict):
        raise ValueError('Docker auths and registry entry must be objects')
    auths.setdefault(registry, {})['auth'] = auth
    write(path, json.dumps(config, indent=2) + '\n')


if __name__ == '__main__':
    run(setup)
