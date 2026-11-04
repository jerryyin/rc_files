import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch


@unittest.skipUnless(sys.platform == 'linux', 'Linux login shell')
class LoginShellTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix='rc-shell-')
        self.addCleanup(temporary.cleanup)
        self.home = Path(temporary.name)
        entry = Path(__file__).resolve().parents[1] / '__main__.py'
        spec = importlib.util.spec_from_file_location('zsh_setup', entry)
        self.shell = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.shell)

    def configure(self, current: str = '/bin/bash', status: int = 1, redirected: str = '0') -> None:
        with patch.dict(os.environ, HOME=str(self.home), RC_SETUP_REDIRECTED=redirected), \
                patch.object(self.shell.pwd, 'getpwuid', return_value=SimpleNamespace(pw_name='fixture', pw_shell=current)), \
                patch.object(self.shell.shutil, 'which', return_value='/bin/zsh'), \
                patch.object(self.shell.subprocess, 'run', return_value=SimpleNamespace(returncode=status)) as run:
            self.shell.login_shell()
            if current == '/bin/zsh' or redirected == '1':
                run.assert_not_called()

    def test_existing_shell_and_redirected_home_leave_account_alone(self) -> None:
        self.configure(current='/bin/zsh')
        self.configure(redirected='1')
        self.assertFalse((self.home / '.bashrc').exists())

    def test_successful_account_change_needs_no_bash_fallback(self) -> None:
        self.configure(status=0)
        self.assertFalse((self.home / '.bashrc').exists())

    def test_fallback_preserves_local_content_and_is_repeatable(self) -> None:
        bashrc = self.home / '.bashrc'
        bashrc.write_text('# personal settings\n')
        self.configure()
        before = bashrc.stat().st_mtime_ns
        self.configure()
        self.assertEqual(bashrc.stat().st_mtime_ns, before)
        self.assertTrue(bashrc.read_text().startswith('# personal settings\n'))
        self.assertEqual(bashrc.read_text().count('auto-exec zsh (chsh unavailable) >>>'), 1)


@unittest.skipUnless(shutil.which('zsh'), 'Zsh PATH filtering')
class WslPathTests(unittest.TestCase):
    def path_after(self, entries: list[str], distro: str) -> list[str]:
        script = Path(__file__).resolve().parents[2] / '.linux/.config/zsh/wsl-path.zsh'
        result = subprocess.run([shutil.which('zsh'), '-f', '-c', 'source "$1"; print -rl -- $path', 'zsh', str(script)],
                                env={'PATH': ':'.join(entries), 'WSL_DISTRO_NAME': distro},
                                capture_output=True, text=True, check=True)
        return result.stdout.splitlines()

    def test_wsl_keeps_only_windows_tools_used_from_linux(self) -> None:
        entries = ['/usr/bin', '/mnt/c/WINDOWS/system32', '/mnt/c/WINDOWS', '/mnt/c/WINDOWS/System32/Wbem',
                   '/mnt/c/WINDOWS/System32/WindowsPowerShell/v1.0/', '/mnt/c/Program Files/PowerShell/7/',
                   '/mnt/c/Program Files/nodejs/', '/mnt/c/Program Files/npm', '/mnt/c/WINDOWS/system32',
                   '/mnt/c/Program Files/cursor/resources/app/bin', '/home/fixture/.local/bin',
                   '/mnt/c/Users/fixture/AppData/Local/Programs/Microsoft VS Code/bin', '/mnt/c/Program Files/PowerShell/7']
        self.assertEqual(self.path_after(entries, 'Ubuntu'), [
            '/usr/bin', '/home/fixture/.local/bin', '/mnt/c/WINDOWS/system32', '/mnt/c/WINDOWS',
            '/mnt/c/WINDOWS/System32/WindowsPowerShell/v1.0', '/mnt/c/Program Files/PowerShell/7',
            '/mnt/c/Program Files/cursor/resources/app/bin',
            '/mnt/c/Users/fixture/AppData/Local/Programs/Microsoft VS Code/bin'])

    def test_other_linux_hosts_keep_their_path(self) -> None:
        entries = ['/usr/bin', '/mnt/c/Program Files/npm', '/mnt/data/tools/bin']
        self.assertEqual(self.path_after(entries, ''), entries)
