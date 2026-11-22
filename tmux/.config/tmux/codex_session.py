"""Resolve the source conversation for an ask-agent fork."""

from contextlib import closing
import json
import os
from pathlib import Path, PureWindowsPath
import re
import sqlite3
import sys

THREAD_TITLE = re.compile(r'[0-9a-f]{8}-[0-9a-f-]{12,27}(?:\.\.\.|…)?')

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


def identify(db: sqlite3.Connection, home: Path, title: str, prompts: list[str], passage: str) -> tuple[str, str] | None:
    threads = dict(db.execute("SELECT id, cwd FROM threads WHERE archived = 0 AND source IN ('cli','vscode')"))
    # Codex truncates its thread-id-only terminal title to 32 characters.
    if THREAD_TITLE.fullmatch(title):
        ids = [sid for sid in threads if sid.startswith(title.rstrip('.…'))]
        if len(ids) == 1:
            return ids[0], local_path(threads[ids[0]])
        return None

    # Clients started before the title setting was installed still display
    # submitted prompts. Ignore the empty composer's suggestion at the bottom.
    history = home / 'history.jsonl'
    prompt_ids = set()
    if prompts and history.is_file():
        entries = []
        with history.open(encoding='utf-8') as stream:
            for line in stream:
                try:
                    record = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if record.get('session_id') in threads:
                    entries.append((record['session_id'], ' '.join(record['text'].split())))
        for prompt in reversed(prompts):
            prefix = ' '.join(prompt.split())
            if len(prefix) < 12:
                continue
            prompt_ids = {sid for sid, text in entries if text.startswith(prefix)}
            if prompt_ids:
                break

    selected = ' '.join(passage.split())
    histories = sorted(home.glob('thread_history_[0-9]*.sqlite'))
    if len(selected) >= 16 and histories:
        with closing(sqlite3.connect(histories[-1].as_uri() + '?mode=ro', uri=True)) as messages:
            rows = messages.execute("SELECT thread_id, json_extract(item_json,'$.text') "
                                    "FROM thread_items WHERE item_type = 'agentMessage'")
            replies = {sid for sid, text in rows if sid in threads and text and selected in ' '.join(text.split())}
        if replies:
            prompt_ids = replies & prompt_ids if prompt_ids else replies
    if len(prompt_ids) == 1:
        sid = prompt_ids.pop()
        return sid, local_path(threads[sid])
    return None


def choose(db: sqlite3.Connection, directory: str) -> tuple[str, str]:
    rows = db.execute("SELECT id, cwd, title FROM threads WHERE archived = 0 "
                      "AND source IN ('cli', 'vscode') ORDER BY updated_at DESC").fetchall()
    matches = [row for row in rows if PureWindowsPath(local_path(row[1])) == PureWindowsPath(local_path(directory))]
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
        with closing(database()) as db:
            print(from_process(db, sys.argv[1], sys.argv[2]))
    except (ValueError, sqlite3.Error) as error:
        sys.exit(f'ask-agent: {error}')
