"""Install configured applications, link settings and prepare plugins."""

from __future__ import annotations

import argparse
from dataclasses import asdict
from datetime import datetime
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

from context import environment, prepare
import links
import packages
import system


def arguments(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', nargs='?', default='setup',
                        choices=('setup', 'credentials', 'prerequisites', 'plan', 'apply', 'migrate', 'check', 'link'))
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
    parser.add_argument('--no-install', action='store_true', help='reuse installed tools; skip system package and CLI installation')
    parser.add_argument('--scope', choices=('machine', 'user'), default='', help='limit prerequisite installation scope')
    parser.add_argument('--skip-setup', action='append', default=[], metavar='PACKAGE', help='link a package but skip its application setup entry')
    parser.add_argument('--update', action='store_true', help='ask selected packages to update installed dependencies')
    parser.add_argument('--vault', type=Path, help='existing vault for the explicit credentials phase')
    parser.add_argument('--persistent-root', type=Path, help='existing private storage for login persistence')
    parser.add_argument('--save', action='store_true', help='save local logins to persistent storage (credentials only)')
    return parser.parse_args(argv)


def credentials(args: argparse.Namespace, tracked: dict[str, str]) -> int:
    settings = environment(args.home, args.update)
    settings.update(PYTHONPATH=str(Path(__file__).resolve().parent), RC_SETUP_INSTALL='0',
                    RC_CREDENTIALS_VAULT=str((args.vault or args.home / 'vault').resolve()),
                    RC_CREDENTIALS_ROOT=str(args.persistent_root.resolve()) if args.persistent_root else '',
                    RC_CREDENTIALS_SAVE=str(int(args.save)), RC_SETUP_REPO=str(args.repo))
    for package in links.package_names(tracked, args.package):
        name = f'{package}/.setup/credentials.py'
        if name in tracked:
            entry = links.resolve_source(args.repo / name, args.repo, tracked)
            print(f'Credentials: {package}', flush=True)
            subprocess.run([sys.executable, '-B', str(entry)], cwd=entry.parent,
                           env=settings, check=True)
    return 0


def main(argv: list[str] | None = None) -> int:
    args = arguments(argv)
    args.repo = args.repo.resolve(strict=True)
    args.home = args.home.resolve()
    if args.action != 'credentials' and (args.vault or args.persistent_root or args.save):
        raise ValueError('--vault, --persistent-root and --save require the credentials action')
    if args.action == 'credentials' and (args.config_only or args.skip_setup or args.scope):
        raise ValueError('Credentials cannot be combined with configuration or installation options')
    if args.save and not args.persistent_root:
        raise ValueError('--save requires --persistent-root')
    if args.action in ('plan', 'apply', 'migrate', 'check', 'link'):
        return links.run(args)
    native = 'windows' if os.name == 'nt' else sys.platform
    if not args.config_only and args.platform != native:
        raise ValueError('Application setup must run on its target platform')
    if not shutil.which('git'):
        raise ValueError('Required commands are missing: git')
    if args.action == 'credentials':
        return credentials(args, links.tracked_files(args.repo))
    backup = args.backup or Path(os.environ.get('BACKUP_DIR', str(
        args.home / '.dotfiles-backup' / datetime.now().strftime('%Y%m%d-%H%M%S'))))
    tracked = links.tracked_files(args.repo)
    selected = links.package_names(tracked, args.package)
    setup_environment = environment(args.home, args.update)
    setup_environment['PYTHONPATH'] = str(Path(__file__).resolve().parent)
    setup_environment['RC_SETUP_INSTALL'] = str(int(not args.no_install))
    setup_environment['RC_SETUP_REPO'] = str(args.repo)
    if not args.config_only:
        selection = packages.discover(args.repo, tracked, args.package, args.platform)
        selected = selection.names
        with_environment = dict(os.environ)
        try:
            os.environ.update(setup_environment)
            if args.action == 'prerequisites' and args.json:
                system.refresh_path()
                print(json.dumps([asdict(package) for package in selection.requirements
                                  if (not args.scope or package.scope == args.scope)
                                  and (package.winget if os.name == 'nt' else package.apt)
                                  and not system.installed(package)]))
                return 0
            system.install(selection.requirements, scope=args.scope, allow=not args.no_install)
            setup_environment['PATH'] = os.environ['PATH']
        finally:
            os.environ.clear()
            os.environ.update(with_environment)
        if args.package:
            args.package = selected
    if args.action == 'prerequisites':
        return 0
    args.action = 'apply' if args.package else 'migrate'
    args.backup = backup.resolve()
    if links.run(args):
        return 1
    if not args.config_only:
        prepare(setup_environment)
        for package in selected:
            name = f'{package}/.setup/__main__.py'
            if name in tracked and package not in args.skip_setup:
                entry = links.resolve_source(args.repo / name, args.repo, tracked)
                print(f'Setup: {package}', flush=True)
                subprocess.run([sys.executable, '-B', str(entry)], cwd=entry.parent,
                               env=setup_environment, check=True)
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
