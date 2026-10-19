"""Link this checkout's configuration and prepare the installed applications."""

from __future__ import annotations

import argparse
from datetime import datetime
import os
from pathlib import Path
import shutil
import subprocess
import sys

from context import environment
import links


def arguments(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', nargs='?', default='setup',
                        choices=('setup', 'plan', 'apply', 'migrate', 'check', 'link'))
    parser.add_argument('--repo', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--home', type=Path, default=Path.home())
    parser.add_argument('--platform', choices=('linux', 'windows', 'darwin'),
                        default='windows' if os.name == 'nt' else sys.platform)
    parser.add_argument('--root', action='append', default=[], metavar='NAME=PATH')
    parser.add_argument('--package', action='append', default=[])
    parser.add_argument('--json', action='store_true')
    parser.add_argument('--backup', type=Path)
    parser.add_argument('--replace-existing', action='store_true')
    parser.add_argument('--source', type=Path)
    parser.add_argument('--target', type=Path)
    parser.add_argument('--config-only', action='store_true', help='link configuration without application setup')
    parser.add_argument('--update', action='store_true', help='ask selected packages to update installed dependencies')
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = arguments(argv)
    args.repo = args.repo.resolve(strict=True)
    args.home = args.home.resolve()
    if args.action in ('plan', 'apply', 'migrate', 'check', 'link'):
        return links.run(args)
    native = 'windows' if os.name == 'nt' else sys.platform
    if not args.config_only and args.platform != native:
        raise ValueError('Application setup must run on its target platform')
    if not shutil.which('git'):
        raise ValueError('Required commands are missing: git')
    backup = args.backup or Path(os.environ.get('BACKUP_DIR', str(
        args.home / '.dotfiles-backup' / datetime.now().strftime('%Y%m%d-%H%M%S'))))
    tracked = links.tracked_files(args.repo)
    packages = links.package_names(tracked, args.package)
    args.action = 'apply' if args.package else 'migrate'
    args.backup = backup.resolve()
    if links.run(args):
        return 1
    if not args.config_only:
        for package in packages:
            name = f'{package}/.setup/__main__.py'
            if name in tracked:
                entry = links.resolve_source(args.repo / name, args.repo, tracked)
                print(f'Setup: {package}', flush=True)
                subprocess.run([sys.executable, '-B', str(entry)], cwd=entry.parent,
                               env=environment(args.home, args.update), check=True)
    print('Setup completed successfully!')
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except subprocess.CalledProcessError as error:
        print(f'setup: command failed ({error.returncode}): {error.cmd}', file=sys.stderr)
        sys.exit(error.returncode)
    except (OSError, ValueError) as error:
        print(f'setup: {error}', file=sys.stderr)
        sys.exit(1)
