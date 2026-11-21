import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import sqlite3
import sys
import tempfile
import unittest
from unittest.mock import patch


helper = Path(__file__).resolve().parents[2] / '.config/tmux/codex_session.py'
spec = importlib.util.spec_from_file_location('codex_session', helper)
session = importlib.util.module_from_spec(spec)
spec.loader.exec_module(session)


class SessionTests(unittest.TestCase):
    def setUp(self) -> None:
        self.db = sqlite3.connect(':memory:')
        self.addCleanup(self.db.close)
        self.db.execute('CREATE TABLE threads (id, cwd, title, archived, source, '
                        'updated_at, recency_at_ms, rollout_path)')

    def add(self, sid: str, cwd: str, time: int, path: str = '') -> None:
        self.db.execute('INSERT INTO threads VALUES (?, ?, ?, 0, ?, ?, ?, ?)',
                        (sid, cwd, sid, 'cli', time, time, path))

    def test_windows_same_directory_requires_a_choice(self) -> None:
        self.add('older', r'\\?\C:\work tree', 1)
        self.add('newer', r'C:\work tree', 2)
        with patch('builtins.input', return_value='2'), contextlib.redirect_stderr(io.StringIO()):
            sid, cwd = session.choose(self.db, 'c:/Work Tree')
        self.assertEqual((sid, session.local_path(cwd)), ('older', r'C:\work tree'))

    def test_windows_can_select_a_different_working_directory_by_id(self) -> None:
        self.add('selected-id', r'C:\actual project', 1)
        with patch('builtins.input', return_value='selected-id'), contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(session.choose(self.db, 'C:/shell'), ('selected-id', r'C:\actual project'))

    def test_windows_pane_title_identifies_older_thread_in_same_folder(self) -> None:
        older = '01a1fc14-8b48-7c01-b2e7-f826b8658155'
        self.add(older, 'C:/work', 1)
        self.add('01a1fc14-9999-7111-8999-999999999999', 'C:/work', 2)
        with tempfile.TemporaryDirectory() as home:
            found = session.identify(self.db, Path(home), '01a1fc14-8b48-7c01-b2e7-f826b...', [], '')
        self.assertEqual(found, (older, 'C:/work'))

    def test_running_client_without_title_matches_visible_prompt(self) -> None:
        self.add('older', 'C:/work', 1)
        self.add('newer', 'C:/work', 2)
        with tempfile.TemporaryDirectory() as home:
            prompt = 'Which instruction reads this register?'
            history = Path(home) / 'history.jsonl'
            history.write_text(json.dumps({'session_id': 'older', 'text': prompt}) + '\n')
            prompts = ['Which instruction reads this', 'Ask Codex to do anything']
            self.assertEqual(session.identify(self.db, Path(home), '', prompts, ''), ('older', 'C:/work'))
            with history.open('a') as stream:
                stream.write(json.dumps({'session_id': 'newer', 'text': prompt}) + '\n')
            self.assertIsNone(session.identify(self.db, Path(home), '', prompts, ''))

    def test_selected_reply_can_identify_a_thread_until_another_thread_contains_it(self) -> None:
        for i, sid in enumerate(('older', 'newer')):
            self.add(sid, 'C:/work', i)
        passage = 'The copper ruler measures seventeen millimeters.'
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            with contextlib.closing(sqlite3.connect(home / 'thread_history_1.sqlite')) as db:
                db.execute('CREATE TABLE thread_items(thread_id, item_type, item_json)')
                for sid, expected in [('older', ('older', 'C:/work')), ('newer', None)]:
                    db.execute("INSERT INTO thread_items VALUES(?,'agentMessage',?)", (sid, json.dumps({'text': passage})))
                    db.commit()
                    self.assertEqual(session.identify(self.db, home, '', [], passage), expected)

    @unittest.skipUnless(sys.platform.startswith('linux'), 'uses Linux process file descriptors')
    def test_open_rollout_wins_over_newer_thread_in_same_directory(self) -> None:
        with tempfile.NamedTemporaryFile() as rollout:
            self.add('source', '/work', 1, rollout.name)
            self.add('newer', '/work', 2)
            self.assertEqual(session.from_process(self.db, str(os.getpid()), '/work'), 'source')


if __name__ == '__main__':
    unittest.main()
