import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


class InstallerTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix='rc-setup-')
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name).resolve()
        self.repo = self.root / "Someone's checkout"
        self.home = self.root / "Someone's home"
        self.repo.mkdir()
        self.home.mkdir()
        self.checkout = Path(__file__).resolve().parents[2]
        self.environment = dict(os.environ, GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM='1')
        self.environment.pop('BACKUP_DIR', None)
        self.git('init', '-q')
        (self.repo / '.setup').mkdir()
        shutil.copyfile(self.checkout / '.setup/deploy.py', self.repo / '.setup/deploy.py')
        self.source = self.repo / 'editor/.editorrc'
        self.source.parent.mkdir()
        self.source.write_text('tracked preference\n')
        self.git('add', '-f', '--all')

    def git(self, *arguments: str) -> None:
        subprocess.run(['git', '-C', str(self.repo), *arguments], env=self.environment,
                       check=True, capture_output=True)

    def setup_rc(self, *arguments: str, wrapper: bool = False,
                 environment: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
        command = (['bash', str(self.checkout / 'install.sh')] if wrapper else
                   [sys.executable, str(self.checkout / 'install.py')])
        return subprocess.run(
            command + ['--repo', str(self.repo), '--home', str(self.home), *arguments],
            cwd=self.root, env=environment or self.environment, text=True, capture_output=True,
        )

    def test_configuration_from_another_working_directory_and_repeat_setup(self) -> None:
        backup = self.root / 'backups'
        result = self.setup_rc('--config-only', '--backup', str(backup))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        target = self.home / '.editorrc'
        self.assertTrue(target.is_symlink())
        self.assertEqual(target.resolve(), self.source)
        before = target.lstat().st_mtime_ns
        self.assertEqual(self.setup_rc('--config-only', '--backup', str(backup)).returncode, 0)
        self.assertEqual(target.lstat().st_mtime_ns, before)
        self.assertFalse(backup.exists())
        self.assertFalse((self.home / '.setup').exists())

    def test_configuration_only_skips_application_actions(self) -> None:
        platform = 'windows' if os.name == 'nt' else sys.platform
        helper = self.repo / '.setup' / platform / 'unexpected.sh'
        helper.parent.mkdir()
        helper.write_text('exit 23\n')
        self.assertEqual(self.setup_rc('--config-only').returncode, 0)

    def test_alternate_home_requires_configuration_only(self) -> None:
        result = self.setup_rc()
        self.assertEqual(result.returncode, 1)
        self.assertIn('Use --config-only for another home', result.stderr)
        self.assertFalse((self.home / '.editorrc').exists())

    def test_conflicting_local_configuration_stops_setup(self) -> None:
        target = self.home / '.editorrc'
        target.write_text('local preference\n')
        result = self.setup_rc('--config-only')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Configuration conflict', result.stdout + result.stderr)
        self.assertNotIn('Setup completed successfully', result.stdout)
        self.assertEqual(target.read_text(), 'local preference\n')

    def test_missing_git_is_reported_before_deployment(self) -> None:
        empty_path = self.root / 'empty-path'
        empty_path.mkdir()
        result = self.setup_rc('--config-only', environment=dict(self.environment, PATH=str(empty_path)))
        self.assertEqual(result.returncode, 1)
        self.assertIn('Required commands are missing: git', result.stderr)
        self.assertFalse((self.home / '.editorrc').exists())

    def test_backup_environment_is_honored(self) -> None:
        target = self.home / '.editorrc'
        target.write_bytes(self.source.read_bytes())
        backup = self.root / 'configured-backup'
        result = self.setup_rc('--config-only', environment=dict(self.environment, BACKUP_DIR=str(backup)))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(target.is_symlink())
        saved = list(backup.iterdir())
        self.assertEqual(len(saved), 1)
        self.assertEqual(saved[0].read_bytes(), self.source.read_bytes())

    @unittest.skipUnless(sys.platform == 'linux', 'Linux Bash compatibility entry point')
    def test_bash_wrapper_forwards_arguments(self) -> None:
        result = self.setup_rc('--config-only', wrapper=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual((self.home / '.editorrc').resolve(), self.source)

    @unittest.skipUnless(sys.platform == 'linux', 'Linux application setup')
    def test_platform_actions_run_in_order_and_preserve_failure_status(self) -> None:
        actions = self.repo / '.setup/linux'
        actions.mkdir()
        (actions / '01-first.sh').write_text('echo first > "$HOME/order"\n')
        (actions / '02-fail.sh').write_text('exit 23\n')
        (actions / '03-later.sh').write_text('echo later >> "$HOME/order"\n')
        foreign = self.repo / '.setup/windows'
        foreign.mkdir()
        (foreign / 'unexpected.sh').write_text('exit 42\n')
        result = self.setup_rc(environment=dict(self.environment, HOME=str(self.home)))
        self.assertEqual(result.returncode, 23, result.stdout + result.stderr)
        self.assertEqual((self.home / 'order').read_text(), 'first\n')
        self.assertNotIn('Setup completed successfully', result.stdout)


if __name__ == '__main__':
    unittest.main()
