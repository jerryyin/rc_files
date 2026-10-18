#!/usr/bin/env python3
"""Deploy this checkout and prepare the applications for the current platform."""

from __future__ import annotations

import argparse
from datetime import datetime
import os
from pathlib import Path
import shutil
import subprocess
import sys


def arguments(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--home', type=Path, default=Path.home())
    parser.add_argument('--backup', type=Path)
    parser.add_argument('--root', action='append', default=[], metavar='NAME=PATH')
    parser.add_argument('--config-only', action='store_true',
                        help='deploy configuration without application setup')
    return parser.parse_args(argv)


def application_scripts(repo: Path, platform: str, config_only: bool) -> list[Path]:
    return [] if config_only else sorted((repo / '.setup' / platform).glob('*.sh'))


def main(argv: list[str] | None = None) -> int:
    args = arguments(argv)
    repo = args.repo.resolve(strict=True)
    home = args.home.resolve()
    if home != Path.home().resolve() and not args.config_only:
        raise ValueError('Use --config-only for another home; application setup targets the current account')
    platform = 'windows' if os.name == 'nt' else sys.platform
    scripts = application_scripts(repo, platform, args.config_only)
    required = ['git'] + (['bash', 'curl'] if scripts else [])
    missing = [name for name in required if shutil.which(name) is None]
    if missing:
        raise ValueError('Required commands are missing: ' + ', '.join(missing))
    default_backup = home / '.dotfiles-backup' / datetime.now().strftime('%Y%m%d-%H%M%S')
    backup = args.backup or Path(os.environ.get('BACKUP_DIR', str(default_backup)))
    command = [sys.executable, str(repo / '.setup/deploy.py'), 'migrate',
               '--repo', str(repo), '--home', str(home), '--backup', str(backup.resolve())]
    for root in args.root:
        command.extend(['--root', root])
    subprocess.run(command, check=True)
    if platform == 'linux' and (home / '.ssh').is_dir():
        (home / '.ssh').chmod(0o700)
    environment = dict(os.environ, HOME=str(home))
    for script in scripts:
        subprocess.run(['bash', str(script)], cwd=repo, env=environment, check=True)
    print('Setup completed successfully!')
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except subprocess.CalledProcessError as error:
        sys.exit(error.returncode)
    except (OSError, ValueError) as error:
        print(f'setup: {error}', file=sys.stderr)
        sys.exit(1)
