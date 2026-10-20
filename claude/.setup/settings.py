"""Seed public Claude preferences or explicitly apply the gateway credential."""

from __future__ import annotations

import json
import os
from pathlib import Path

from private import read_json, secret, write

Json = str | int | float | bool | None | list['Json'] | dict[str, 'Json']


def read_settings(path: Path) -> dict[str, Json]:
    result = read_json(path)
    if not isinstance(result.get('env', {}), dict):
        raise ValueError(f'{path} env field must be a JSON object')
    return result


def merge(base: dict[str, Json], overrides: dict[str, Json]) -> dict[str, Json]:
    result = base.copy()
    for name, value in overrides.items():
        previous = result.get(name)
        result[name] = merge(previous, value) if isinstance(previous, dict) and isinstance(value, dict) else value
    return result


def setup(home: Path, *, credentials: bool = False) -> None:
    directory = Path(os.environ.get('CLAUDE_CONFIG_DIR', str(home / '.claude'))).expanduser().resolve()
    repo = Path(__file__).resolve().parents[2]
    if directory.is_relative_to(repo):
        raise ValueError('Private Claude settings must live outside rc_files')
    if os.environ.get('RC_SETUP_REDIRECTED') == '1' and not directory.is_relative_to(home.resolve()):
        raise ValueError('Redirected Claude configuration must be inside its test home')
    target = directory / 'settings.json'
    linked = target.is_symlink()
    if linked and not target.resolve().is_relative_to(repo / 'claude'):
        raise ValueError(f'Unrelated settings link at {target}; reconcile it before setup')
    template = read_settings(Path(__file__).with_name('settings.json.template'))
    existing = read_settings(target) if target.exists() else {}
    settings = merge(existing, template) if os.environ.get('RC_SETUP_UPDATE') == '1' else merge(template, existing)
    environment = settings['env']
    assert isinstance(environment, dict)
    key = secret('CLAUDE_KEY_FILE', 'claude_key.txt') if credentials else None
    if credentials and key is None:
        return
    if key is not None:
        previous = environment.get('ANTHROPIC_CUSTOM_HEADERS', '')
        if not isinstance(previous, str):
            raise ValueError('ANTHROPIC_CUSTOM_HEADERS must be a string')
        headers = [line for line in previous.splitlines()
                   if line.partition(':')[0].strip().lower() != 'ocp-apim-subscription-key']
        headers.append('Ocp-Apim-Subscription-Key: ' + key)
        environment['ANTHROPIC_CUSTOM_HEADERS'] = '\n'.join(headers)
    if existing == settings and not linked:
        return
    write(target, json.dumps(settings, indent=2, ensure_ascii=False) + '\n')
    print(f'Claude settings prepared: {target}')
