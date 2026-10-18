import json
import os
from pathlib import Path
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
        self.source = self.repo / 'editor/.editorrc'
        self.source.parent.mkdir()
        self.source.write_text('tracked preference\n')
        self.git('add', '-f', '--all')

    def git(self, *arguments: str) -> None:
        subprocess.run(['git', '-C', str(self.repo), *arguments], env=self.environment,
                       check=True, capture_output=True)

    def setup_rc(self, *arguments: str,
                 environment: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
        command = [sys.executable, str(self.checkout / '.setup')]
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

    def test_foreign_platform_cannot_run_application_installers(self) -> None:
        foreign = 'linux' if os.name == 'nt' else 'windows'
        result = self.setup_rc('--platform', foreign)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Application setup must run on its target platform', result.stderr)
        self.assertFalse((self.home / '.editorrc').exists())

    def test_windows_deploys_one_shared_vimrc(self) -> None:
        result = self.setup_rc('plan', '--repo', str(self.checkout), '--platform', 'windows',
                               '--package', 'vim', '--json')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        source = self.checkout / 'vim/.vimrc'
        links = json.loads(result.stdout)['links']
        entries = {Path(link['target']).name for link in links
                   if Path(link['source']) == source}
        self.assertEqual(entries, {'.vimrc'})
        self.assertNotIn(self.home / '_vimrc', {Path(link['target']) for link in links})

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


if __name__ == '__main__':
    unittest.main()
