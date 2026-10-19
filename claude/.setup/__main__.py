"""Prepare private Claude settings from tracked preferences and the vault key."""

from __future__ import annotations

import csv
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


Json = str | int | float | bool | None | list['Json'] | dict[str, 'Json']


def read_settings(path: Path) -> dict[str, Json]:
    try:
        result = json.loads(path.read_text(encoding='utf-8-sig'))
    except json.JSONDecodeError:
        raise ValueError(f'Invalid JSON in {path}; settings were left unchanged') from None
    if not isinstance(result, dict) or not isinstance(result.get('env', {}), dict):
        raise ValueError(f'{path} and its env field must be JSON objects')
    return result


def merge(base: dict[str, Json], overrides: dict[str, Json]) -> dict[str, Json]:
    result = base.copy()
    for name, value in overrides.items():
        previous = result.get(name)
        result[name] = merge(previous, value) if isinstance(previous, dict) and isinstance(value, dict) else value
    return result


def private_file(path: Path) -> None:
    if os.name == 'nt':
        owner = subprocess.check_output(['whoami', '/user', '/fo', 'csv', '/nh'], text=True)
        sid = next(csv.reader([owner.strip()]))[-1]
        subprocess.run(['icacls', str(path), '/inheritance:r', '/grant:r',
                        f'*{sid}:(F)', '*S-1-5-18:(F)', '*S-1-5-32-544:(F)'],
                       check=True, capture_output=True)
    else:
        path.chmod(0o600)


def save_settings(path: Path, settings: dict[str, Json]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode='w', encoding='utf-8', dir=path.parent, delete=False) as stream:
            temporary = Path(stream.name)
            private_file(temporary)
            stream.write(json.dumps(settings, indent=2, ensure_ascii=False) + '\n')
        os.replace(temporary, path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def setup(home: Path) -> None:
    directory = Path(os.environ.get('CLAUDE_CONFIG_DIR', str(home / '.claude'))).expanduser().resolve()
    key_file = Path(os.environ.get('CLAUDE_KEY_FILE', str(home / 'vault/claude_key.txt'))).expanduser().resolve()
    repo = Path(__file__).resolve().parents[2]
    if directory.is_relative_to(repo):
        raise ValueError('Private Claude settings must live outside rc_files')
    if os.environ.get('RC_SETUP_REDIRECTED') == '1' and any(
            not path.is_relative_to(home.resolve()) for path in (directory, key_file)):
        raise ValueError('Redirected Claude setup requires configuration and vault paths inside its test home')
    target = directory / 'settings.json'
    linked = target.is_symlink()
    if linked and not target.resolve().is_relative_to(repo / 'claude'):
        raise ValueError(f'Unrelated settings link at {target}; reconcile it before setup')
    template = read_settings(Path(__file__).with_name('settings.json.template'))
    existing = read_settings(target) if target.exists() else {}
    settings = merge(existing, template) if os.environ.get('RC_SETUP_UPDATE') == '1' else merge(template, existing)
    environment = settings['env']
    assert isinstance(environment, dict)
    if key_file.exists():
        key = key_file.read_text(encoding='utf-8-sig').strip()
        if not key or not key.isascii() or not key.isprintable() or any(character.isspace() for character in key):
            raise ValueError('Claude subscription key must be nonempty printable ASCII without whitespace')
        previous = environment.get('ANTHROPIC_CUSTOM_HEADERS', '')
        if not isinstance(previous, str):
            raise ValueError('ANTHROPIC_CUSTOM_HEADERS must be a string')
        headers = [line for line in previous.splitlines()
                   if line.partition(':')[0].strip().lower() != 'ocp-apim-subscription-key']
        headers.append('Ocp-Apim-Subscription-Key: ' + key)
        environment['ANTHROPIC_CUSTOM_HEADERS'] = '\n'.join(headers)
    else:
        print('Claude: vault key is missing; existing credentials are preserved. Rerun setup after syncing the vault.')
    if existing == settings and not linked:
        return
    save_settings(target, settings)
    print(f'Claude settings prepared: {target}')


if __name__ == '__main__':
    try:
        setup(Path.home())
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f'Claude setup: {error}', file=sys.stderr)
        sys.exit(1)
