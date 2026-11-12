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


def seed_state(directory: Path, home: Path, api_key: Json) -> None:
    """Add the answers to Claude's first-run questions to its untracked state file.

    Marks onboarding and the auto-mode offer as seen, approves the template's placeholder
    API key unless it was rejected, and trusts `home`. Other state is kept. An unreadable
    state file is reported and left for Claude to recover.
    """
    target = directory / '.claude.json' if 'CLAUDE_CONFIG_DIR' in os.environ else home / '.claude.json'
    try:
        existing = read_json(target)
    except ValueError as error:
        print(f'SKIP: {error}')
        return
    state = json.loads(json.dumps(existing))
    responses = state.setdefault('customApiKeyResponses', {'approved': [], 'rejected': []})
    projects = state.setdefault('projects', {})
    if not (isinstance(responses, dict) and isinstance(projects, dict)
            and all(isinstance(responses.get(name, []), list) for name in ('approved', 'rejected'))):
        print(f'SKIP: unexpected structure in {target}; file preserved')
        return
    state['hasCompletedOnboarding'] = True
    state['hasSeenAutoDefaultNudge'] = True  # Keeps the template's bypass default.
    if isinstance(api_key, str) and api_key.strip():
        # Claude records approval by the key's last 20 characters.
        truncated = api_key.strip()[-20:]
        approved = responses.setdefault('approved', [])
        if truncated not in approved and truncated not in responses.setdefault('rejected', []):
            approved.append(truncated)
    # Claude stops looking for trusted parents at a Git root, so checkouts below
    # home still ask once. New project entries default to false, which is not a refusal.
    project = projects.setdefault(home.resolve().as_posix(), {})
    if isinstance(project, dict):
        project['hasTrustDialogAccepted'] = True
    if state == existing:
        return
    write(target, json.dumps(state, indent=2, ensure_ascii=False) + '\n')
    print(f'Claude first-run state prepared: {target}')


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
    seed_state(directory, home, environment.get('ANTHROPIC_API_KEY'))
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
