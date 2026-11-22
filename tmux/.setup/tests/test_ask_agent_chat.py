"""Run the shared ask-agent question loop with recording claude, codex and tmux."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


chat = Path(__file__).resolve().parents[2] / '.config/tmux/ask-agent-chat.sh'

# Each fake records its arguments and prompt in $LOG, numbered by call.
FAKES = {
    'claude': 'n=$(ls "$LOG" | grep -c "args$") ; printf "%s\\n" "$@" > "$LOG/call$n.args" ; '
              'cat > "$LOG/call$n.prompt" ; echo "answer $n"',
    'codex': 'n=$(ls "$LOG" | grep -c "args$") ; printf "%s\\n" "$@" > "$LOG/call$n.args" ; '
             'cat > "$LOG/call$n.prompt" ; while [ "$1" != -o ]; do shift; done ; echo "answer $n" > "$2"',
    'tmux': 'printf "%s\\n" "$*" >> "$LOG/tmux"',
    'resolver': 'echo x >> "$LOG/resolved" ; printf "$RESOLVED"',
}


@unittest.skipUnless(shutil.which('bash') and os.name != 'nt', 'runs the loop under bash')
class ChatTests(unittest.TestCase):
    def setUp(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)
        self.log = self.root / 'log'
        self.log.mkdir()
        bin_dir = self.root / 'bin'
        bin_dir.mkdir()
        for name, body in FAKES.items():
            fake = bin_dir / name
            fake.write_text('#!/usr/bin/env bash\n' + body + '\n')
            fake.chmod(0o755)
        self.passage = self.root / 'passage'
        self.passage.write_text('The copper ruler measures seventeen millimeters.\n')
        (self.root / 'passage.context').write_text('{}')
        self.env = dict(os.environ, HOME=str(self.root), LOG=str(self.log),
                        PATH=f'{bin_dir}:{os.environ["PATH"]}')

    def run_chat(self, *args: str, answers: str) -> str:
        result = subprocess.run(['bash', str(chat), '%9', str(self.passage), *args], input=answers,
                                env=self.env, capture_output=True, encoding='utf-8', timeout=30)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout

    def test_known_session_forks_for_each_question_and_follow_up_sees_the_thread(self) -> None:
        out = self.run_chat('claude', 'source-id', str(self.root), answers='What is it?\nAnd its unit?\n\n')
        self.assertIn('answer 0', out)
        self.assertIn('answer 1', out)
        args = (self.log / 'call0.args').read_text().split()
        self.assertEqual(args[:5], ['-p', '--resume', 'source-id', '--fork-session', '--no-session-persistence'])
        first = (self.log / 'call0.prompt').read_text()
        self.assertIn('<passage>\nThe copper ruler measures seventeen millimeters.\n</passage>', first)
        self.assertNotIn('Earlier side questions', first)
        follow_up = (self.log / 'call1.prompt').read_text()
        self.assertIn('<question>What is it?</question>\n<answer>answer 0</answer>', follow_up)
        self.assertTrue(follow_up.endswith('Question: And its unit?\n'))
        self.assertEqual((self.log / 'tmux').read_text(), 'select-pane -t %9\n')
        self.assertEqual(list(self.root.glob('passage*')), [])

    def test_resolver_runs_once_on_the_first_question(self) -> None:
        self.env['RESOLVED'] = f'codex\\tthread-id\\t{self.root}'
        out = self.run_chat('--', 'resolver', answers='What is it?\nAnd its unit?\n\n')
        self.assertIn('codex session thread-i', out)
        self.assertEqual((self.log / 'resolved').read_text(), 'x\n')
        self.assertEqual((self.log / 'call1.args').read_text().split()[:3], ['exec', 'fork', 'thread-id'])
        self.assertIn('<answer>answer 0</answer>', (self.log / 'call1.prompt').read_text())

    def test_empty_resolver_output_closes_without_asking(self) -> None:
        self.env['RESOLVED'] = ''
        self.run_chat('--', 'resolver', answers='What is it?\n')
        self.assertFalse(list(self.log.glob('call*')))
        self.assertEqual(list(self.root.glob('passage*')), [])


if __name__ == '__main__':
    unittest.main()
