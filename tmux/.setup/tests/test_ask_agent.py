import contextlib
import importlib.util
import io
import os
from pathlib import Path
import sqlite3
import sys
import tempfile
import unittest
from unittest.mock import patch


helper = Path(__file__).resolve().parents[2] / '.config/tmux/codex-session.py'
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

    @unittest.skipUnless(sys.platform.startswith('linux'), 'uses Linux process file descriptors')
    def test_open_rollout_wins_over_newer_thread_in_same_directory(self) -> None:
        with tempfile.NamedTemporaryFile() as rollout:
            self.add('source', '/work', 1, rollout.name)
            self.add('newer', '/work', 2)
            self.assertEqual(session.from_process(self.db, str(os.getpid()), '/work'), 'source')


if __name__ == '__main__':
    unittest.main()
