import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
import uuid


@unittest.skipUnless(shutil.which('psmux' if os.name == 'nt' else 'tmux'), 'native multiplexer required')
class NativeConfigurationTests(unittest.TestCase):
    def test_shared_edits_reach_the_native_server_without_setup(self) -> None:
        checkout = Path(__file__).resolve().parents[2]
        with tempfile.TemporaryDirectory(prefix='rc-mux-runtime-') as directory:
            root = Path(directory).resolve()
            repo = root / 'source'
            home = root / "Someone's home"
            shutil.copytree(checkout / 'tmux', repo / 'tmux')
            environment = {key: value for key, value in os.environ.items()
                           if not key.startswith(('PSMUX_', 'TMUX'))}
            environment.update(HOME=str(home), GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM='1')
            if os.name == 'nt':
                environment.update(USERPROFILE=str(home), PSMUX_DATA_DIR=str(root / 'servers'), PSMUX_NO_WARM='1')

            def run(*command: str) -> str:
                return subprocess.check_output(command, env=environment, text=True, stderr=subprocess.STDOUT)

            run('git', 'init', '-q', str(repo))
            run('git', '-C', str(repo), 'add', '-f', '.')
            run(sys.executable, str(checkout / '.setup'), 'apply', '--repo', str(repo), '--home', str(home))
            native = shutil.which('psmux' if os.name == 'nt' else 'tmux')
            server = [native, '-L', 'rc-test-' + uuid.uuid4().hex]
            entry = home / ('.psmux.conf' if os.name == 'nt' else '.tmux.conf')
            command = ['--', 'pwsh', '-NoProfile', '-Command', 'Start-Sleep 90'] if os.name == 'nt' else ['sleep 90']
            try:
                run(*server, '-f', str(entry), 'new-session', '-d', '-s', 'verify', *command)
                self.assertIn('`', run(*server, 'show-options', '-g', 'prefix'))
                common = home / '.config/tmux/common.conf'
                self.assertTrue(common.is_symlink())
                with common.open('a', encoding='utf-8', newline='\n') as output:
                    output.write('\nset-option -g prefix C-a\nset -g base-index 1\n')
                self.assertIn('C-a', (repo / 'tmux/.config/tmux/common.conf').read_text())
                run(*server, 'source-file', str(entry))
                self.assertIn('C-a', run(*server, 'show-options', '-g', 'prefix'))
                self.assertIn('1', run(*server, 'show-options', '-g', 'base-index'))
                self.assertFalse((home / '.psmux/generated.conf').exists())
            finally:
                subprocess.run([*server, 'kill-server'], env=environment, capture_output=True)
