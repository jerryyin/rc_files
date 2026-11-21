"""Exercise the copy-mode binding on a private psmux server with a recording Codex."""

from contextlib import closing
import json
import os
from pathlib import Path
import shutil
import sqlite3
import subprocess
import tempfile
import time
import unittest


package = Path(__file__).resolve().parents[2]


@unittest.skipUnless(os.name == 'nt' and shutil.which('psmux.exe'), 'requires native Windows psmux')
class AskPaneTests(unittest.TestCase):
    def test_selection_opens_and_forks_the_source_in_a_shared_working_directory(self) -> None:
        with tempfile.TemporaryDirectory(prefix='ask pane ', ignore_cleanup_errors=True) as tmp:
            home = Path(tmp)
            shared = home / '.config/tmux'
            shutil.copytree(package / '.config/tmux', shared)
            shutil.copytree(package / '.windows/.tmux', home / '.tmux')
            codex = home / '.codex'
            codex.mkdir()
            server = home / 'server'
            server.mkdir()
            env = {k: v for k, v in os.environ.items() if not k.startswith(('PSMUX_', 'TMUX'))}
            env.update(HOME=tmp, USERPROFILE=tmp, CODEX_HOME=str(codex), PSMUX_DATA_DIR=str(server),
                       PSMUX_TARGET_SESSION='ask', PSMUX_NO_WARM='1')

            selected = 'Selected λ with "quotes" and $(literal)'
            source_prompt = 'Which instruction reads this register?'
            source_id = '238c4000-1111-4040-9000-111111111111'
            with closing(sqlite3.connect(codex / 'state_5.sqlite')) as db, db:
                db.execute('CREATE TABLE threads(id, cwd, title, archived, source, updated_at)')
                for order, sid in enumerate((source_id, '238c4000-2222-4040-9000-222222222222')):
                    db.execute("INSERT INTO threads VALUES(?,?,?,0,'cli',?)", (sid, tmp, 'same folder', order))
            (codex / 'history.jsonl').write_text(json.dumps(dict(session_id=source_id, text=source_prompt)) + '\n')
            shutil.copy2(Path(os.environ['SystemRoot']) / 'System32/ping.exe', home / 'codex.exe')
            source = home / 'source.ps1'
            source.write_text(f"[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)\n"
                              f"[Console]::WriteLine('{selected}')\n[Console]::WriteLine('› {source_prompt}')\n"
                              '& "$PSScriptRoot/codex.exe" -t 127.0.0.1 > $null\n', encoding='utf-8')
            shim = home / '.local/bin/codex'
            shim.parent.mkdir(parents=True)
            shim.write_bytes(b'#!/usr/bin/env bash\nprintf "%s\\n" "$@" > "$CODEX_HOME/args"\n'
                             b'cat > "$CODEX_HOME/prompt"\nwhile [[ $# -gt 1 && $1 != -o ]]; do shift; done\n'
                             b'printf "fixture answer\\n" > "$2"\n')

            def mux(*args: str) -> str:
                return subprocess.check_output(['psmux.exe', *args], env=env, encoding='utf-8')

            def see(text: str) -> str:
                end = time.monotonic() + 20
                while time.monotonic() < end:
                    screen = mux('capture-pane', '-p')
                    if text in screen:
                        return screen
                    time.sleep(0.1)
                self.fail(f'Expected {text!r} in {screen!r}')

            try:
                mux('-f', str(package / '.windows/.psmux.conf'), 'new-session', '-d', '-s', 'ask',
                    '-c', tmp, '--', 'pwsh', '-NoProfile', '-File', str(source))
                see(selected)
                origin = mux('display-message', '-p', '#{pane_id}').strip()
                mux('copy-mode')
                mux('send-keys', '-X', 'history-top')
                mux('send-keys', '-X', 'select-line')
                mux('send-keys', 'a')
                self.assertIn(selected, see('Question>'))
                answer = mux('display-message', '-p', '#{pane_id}').strip()
                mux('send-keys', '-l', 'Explain the register.')
                mux('send-keys', 'Enter')
                see('Follow-up>')
                self.assertEqual((codex / 'args').read_text().splitlines()[:3], ['exec', 'fork', source_id])
                self.assertIn(f'<passage>\n{selected}\n</passage>', (codex / 'prompt').read_text(encoding='utf-8'))
                mux('select-pane', '-t', origin)
                mux('copy-mode')
                mux('send-keys', '-X', 'history-top')
                mux('send-keys', '-X', 'cursor-down')
                mux('send-keys', '-X', 'select-line')
                mux('send-keys', 'a')
                see(f'│ › {source_prompt}')
                self.assertEqual(mux('display-message', '-p', '#{pane_id}').strip(), answer)
                self.assertEqual(set(mux('list-panes', '-F', '#{pane_id}').split()), {origin, answer})
            finally:
                if (server / 'ask.port').exists():
                    mux('kill-server')


if __name__ == '__main__':
    unittest.main()
