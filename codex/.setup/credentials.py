"""Share only Codex file authentication; keep preferences and instructions local."""

import os
from pathlib import Path
import sys

import links
from private import outside_git, persist, run, write


def migrate(directory: Path, stored: Path) -> None:
    if not directory.is_symlink():
        return
    if directory.resolve() != stored.resolve():
        raise ValueError('Unrelated Codex directory link; reconcile it before credential setup')
    outside_git(stored.resolve())
    preferences = directory / 'config.toml'
    content = preferences.read_text() if preferences.exists() else None
    repo = Path(os.environ['RC_SETUP_REPO'])
    planned = links.discover(repo, sys.platform, {'HOME': Path.home()}, [])
    owned = [link for link in planned if link.target.is_relative_to(directory)]
    directory.unlink()
    directory.mkdir()
    if content is not None:
        write(directory / 'config.toml', content)
    for link in owned:
        links.install(link, None)


def setup() -> None:
    root = os.environ.get('RC_CREDENTIALS_ROOT', '')
    if not root or os.name == 'nt':
        return
    directory = Path.home() / '.codex'
    # Alternate CODEX_HOME directories are separate sessions; do not mix them.
    if os.environ.get('CODEX_HOME') and Path(os.environ['CODEX_HOME']).resolve() != directory.resolve():
        raise ValueError('Unset CODEX_HOME before syncing the default Codex login')
    migrate(directory, Path(root) / '.codex')
    persist('.codex/auth.json')


if __name__ == '__main__':
    run(setup)
