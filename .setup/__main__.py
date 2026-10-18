"""Link this checkout's configuration and prepare the installed applications."""

from __future__ import annotations

import argparse
from datetime import datetime
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

from context import Context
import links
import mux
import shell
import vim


def arguments(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', nargs='?', default='setup',
                        choices=('setup', 'plan', 'apply', 'migrate', 'check', 'link', 'vim', 'mux', 'shell'))
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
    parser.add_argument('--update', action='store_true', help='also update installed Vim and mux plugins')
    parser.add_argument('--configure-only', action='store_true', help='vim: only prepare native runtime paths')
    parser.add_argument('--vim-exe', type=Path)
    parser.add_argument('--git-bash', type=Path)
    parser.add_argument('--python-root', type=Path)
    parser.add_argument('--render-only', action='store_true', help='mux: only render native configuration')
    parser.add_argument('--print-config', action='store_true', help='mux: print native configuration without changes')
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = arguments(argv)
    args.repo = args.repo.resolve(strict=True)
    args.home = args.home.resolve()
    if args.action in ('plan', 'apply', 'migrate', 'check', 'link'):
        return links.run(args)
    if args.action == 'mux' and args.print_config:
        configuration = mux.render(args.repo, args.home)
        print(json.dumps(configuration) if args.json else configuration, end='\n' if args.json else '')
        return 0
    native = 'windows' if os.name == 'nt' else sys.platform
    if not args.config_only and args.platform != native:
        raise ValueError('Application setup must run on its target platform')
    if (args.action in ('setup', 'shell') and args.home != Path.home().resolve()
            and not args.config_only):
        raise ValueError('Use --config-only for another home; full setup can change account settings')
    if not shutil.which('git'):
        raise ValueError('Required commands are missing: git')
    backup = args.backup or Path(os.environ.get('BACKUP_DIR', str(
        args.home / '.dotfiles-backup' / datetime.now().strftime('%Y%m%d-%H%M%S'))))
    context = Context(args.repo, args.home, backup.resolve(), args.platform, args.update)
    if args.action == 'setup':
        args.action = 'migrate'
        args.backup = context.backup
        if links.run(args):
            return 1
        if args.platform == 'linux' and (args.home / '.ssh').is_dir():
            (args.home / '.ssh').chmod(0o700)
        if not args.config_only:
            mux.setup(context)
            vim.setup(context, vim_exe=args.vim_exe, git_bash=args.git_bash, python_root=args.python_root)
            if args.platform == 'linux':
                shell.setup(context)
        print('Setup completed successfully!')
    elif args.action == 'vim':
        vim.setup(context, vim_exe=args.vim_exe, git_bash=args.git_bash,
                  python_root=args.python_root, configure_only=args.configure_only)
    elif args.action == 'mux':
        mux.setup(context, render_only=args.render_only)
    elif args.action == 'shell':
        if args.platform != 'linux':
            raise ValueError('Login shell setup is only supported on Linux')
        shell.setup(context)
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
