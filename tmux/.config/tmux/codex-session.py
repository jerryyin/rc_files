"""Resolve the source conversation for an ask-agent fork."""

import os
from pathlib import Path, PureWindowsPath
import sqlite3
import sys


def local_path(directory: str) -> str:
    if directory.startswith('\\\\?\\UNC\\'):
        return '\\\\' + directory[8:]
    return directory.removeprefix('\\\\?\\')


def database() -> sqlite3.Connection:
    home = Path(os.environ.get('CODEX_HOME') or Path.home() / '.codex')
    databases = sorted(home.glob('state_[0-9]*.sqlite'), key=lambda path: int(path.stem.split('_')[-1]))
    if not databases:
        raise ValueError('Codex has no saved conversations here')
    return sqlite3.connect(databases[-1].as_uri() + '?mode=ro', uri=True)


def from_process(db: sqlite3.Connection, pid: str, directory: str) -> str:
    files = set()
    for fd in Path('/proc', pid, 'fd').glob('*'):
        try:
            files.add(os.readlink(fd))
        except OSError:
            continue  # The process can close a descriptor during enumeration.
    rows = db.execute('SELECT id, rollout_path, cwd FROM threads WHERE archived = 0 '
                      'ORDER BY recency_at_ms DESC, updated_at DESC').fetchall()
    for sid, path, _ in rows:
        if path in files:
            return sid
    for sid, _, cwd in rows:
        if cwd == directory:
            return sid
    raise ValueError('no session found for the source process')


def choose(db: sqlite3.Connection, directory: str) -> tuple[str, str]:
    rows = db.execute("SELECT id, cwd, title FROM threads WHERE archived = 0 "
                      "AND source IN ('cli', 'vscode') ORDER BY updated_at DESC").fetchall()
    matches = [row for row in rows if PureWindowsPath(local_path(row[1])) == PureWindowsPath(local_path(directory))]
    if len(matches) == 1:
        return matches[0][0], matches[0][1]
    for number, (sid, _, title) in enumerate(matches[:10], 1):
        print(f'{number:2}. {sid[:8]}  {" ".join(title.split())[:80]}', file=sys.stderr)
    print('Choose a conversation number or paste its ID from Codex /status (Enter closes): ',
          end='', file=sys.stderr, flush=True)
    answer = input().strip()
    if not answer:
        raise SystemExit(0)
    if answer.isdecimal() and 1 <= int(answer) <= min(10, len(matches)):
        return matches[int(answer) - 1][:2]
    for sid, cwd, _ in rows:
        if sid == answer:
            return sid, cwd
    raise ValueError('unknown conversation')


if __name__ == '__main__':
    try:
        with database() as db:
            if sys.argv[1] == 'choose':
                sid, cwd = choose(db, sys.argv[2])
                sys.stdout.buffer.write(f'{sid}\t{local_path(cwd)}'.encode())
            else:
                print(from_process(db, sys.argv[1], sys.argv[2]))
    except (ValueError, sqlite3.Error) as error:
        sys.exit(f'ask-agent: {error}')
