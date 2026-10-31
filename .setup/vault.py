"""Validate which private repository a credential activation may read."""

from pathlib import Path

SCOPES = ('work', 'homelab')
WORK_FILES = frozenset({'gh_token_amdeng.txt', 'claude_key.txt',
                        'atlartifactory_token.txt', 'docker_mkmhub_auth.txt'})
SHARED_FILES = frozenset({'gh_token_jerryyin.txt'})
METADATA = frozenset({'.git', '.gitattributes', '.gitignore', '.vault-scope', 'README.md', 'ssh'})


def allowed(name: str, scope: str) -> bool:
    return scope in SCOPES and (name in SHARED_FILES or scope == ('work' if name in WORK_FILES else 'homelab'))


def validate(path: Path, scope: str) -> None:
    if scope not in SCOPES:
        raise ValueError('Vault scope must be work or homelab')
    if not path.exists():
        return  # SSH bootstrap precedes cloning; other hooks skip missing files.
    marker = path / '.vault-scope'
    if not marker.is_file():
        raise ValueError(f'Missing .vault-scope in {path}; the mixed vault cannot be used')
    if marker.read_text(encoding='utf-8').strip() != scope:
        raise ValueError(f'Vault scope mismatch: expected {scope} at {path}')
    for entry in path.iterdir():
        if entry.name not in METADATA and not allowed(entry.name, scope):
            raise ValueError(f'{entry.name} does not belong in {scope}')
