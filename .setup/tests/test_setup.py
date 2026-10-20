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

    def entry(self, package: str, body: str, *, tracked: bool = True) -> Path:
        entry = self.repo / package / '.setup/__main__.py'
        entry.parent.mkdir(parents=True, exist_ok=True)
        entry.write_text('import os\nfrom pathlib import Path\n' + body, encoding='utf-8')
        if tracked:
            self.git('add', '-f', '--', str(entry))
        return entry

    def test_all_configuration_is_linked_before_any_package_setup(self) -> None:
        self.entry('before-editor', '''
home = Path.home()
assert (home / '.editorrc').read_text() == 'tracked preference\\n'
assert (home / '.last').read_text() == 'last preference'
(home / 'prepared').write_text('ok')
''')
        last = self.repo / 'last/.last'
        last.parent.mkdir()
        last.write_text('last preference')
        self.git('add', '-f', '--', str(last))
        result = self.setup_rc()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual((self.home / 'prepared').read_text(), 'ok')
        self.assertFalse((self.home / '.setup').exists())

    def test_selected_setup_leaves_other_packages_and_links_alone(self) -> None:
        other = self.repo / 'other/.other'
        other.parent.mkdir()
        other.write_text('other preference')
        self.git('add', '-f', '--', str(other))
        self.entry('other', 'raise SystemExit(99)\n')
        self.entry('editor', "(Path.home() / 'prepared').write_text('editor')\n")
        first = self.setup_rc('apply', '--package', 'other')
        self.assertEqual(first.returncode, 0, first.stdout + first.stderr)
        timestamp = (self.home / '.other').lstat().st_mtime_ns
        result = self.setup_rc('--package', 'editor', '--package', 'editor')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(result.stdout.count('Setup: editor'), 1)
        self.assertEqual((self.home / 'prepared').read_text(), 'editor')
        self.assertEqual((self.home / '.other').resolve(), other)
        self.assertEqual((self.home / '.other').lstat().st_mtime_ns, timestamp)

    def test_package_setup_receives_isolated_home_and_update_environment(self) -> None:
        self.entry('editor', '''
import json
import sys
report = {name: os.environ.get(name) for name in
          ('HOME', 'USERPROFILE', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME', 'XDG_DATA_HOME',
           'APPDATA', 'LOCALAPPDATA', 'RC_SETUP', 'RC_SETUP_UPDATE', 'RC_SETUP_REDIRECTED',
           'GIT_CONFIG_GLOBAL', 'GIT_TERMINAL_PROMPT')}
report.update(home=str(Path.home()), python=sys.executable, cwd=str(Path.cwd()))
(Path.home() / 'environment.json').write_text(json.dumps(report))
''')
        before = dict(os.environ)
        for update in (False, True):
            with self.subTest(update=update):
                result = self.setup_rc(*(['--update'] if update else []))
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                report = json.loads((self.home / 'environment.json').read_text())
                self.assertEqual(Path(report['home']), self.home)
                self.assertEqual(Path(report['HOME']), self.home)
                self.assertEqual(report['RC_SETUP'], '1')
                self.assertEqual(report['RC_SETUP_UPDATE'], str(int(update)))
                self.assertEqual(report['RC_SETUP_REDIRECTED'], '1')
                self.assertEqual(report['GIT_CONFIG_GLOBAL'], os.devnull)
                self.assertEqual(report['GIT_TERMINAL_PROMPT'], '0')
                self.assertEqual(Path(report['python']), Path(sys.executable))
                self.assertEqual(Path(report['cwd']), self.repo / 'editor/.setup')
                for name, suffix in (('XDG_CONFIG_HOME', '.config'), ('XDG_CACHE_HOME', '.cache'),
                                     ('XDG_DATA_HOME', '.local/share')):
                    self.assertEqual(Path(report[name]), self.home / suffix)
                if os.name == 'nt':
                    for name, suffix in (('USERPROFILE', ''), ('APPDATA', 'AppData/Roaming'),
                                         ('LOCALAPPDATA', 'AppData/Local')):
                        self.assertEqual(Path(report[name]), self.home / suffix)
        self.assertEqual(dict(os.environ), before)

    def test_repeated_setup_reruns_entries_without_replacing_correct_links(self) -> None:
        self.entry('editor', '''
count = Path.home() / 'runs'
count.write_text(str(int(count.read_text()) + 1) if count.exists() else '1')
''')
        first = self.setup_rc()
        self.assertEqual(first.returncode, 0, first.stdout + first.stderr)
        before = (self.home / '.editorrc').lstat().st_mtime_ns
        second = self.setup_rc()
        self.assertEqual(second.returncode, 0, second.stdout + second.stderr)
        self.assertEqual((self.home / 'runs').read_text(), '2')
        self.assertEqual((self.home / '.editorrc').lstat().st_mtime_ns, before)

    def test_configuration_actions_never_execute_package_entries(self) -> None:
        self.entry('editor', 'raise SystemExit(99)\n')
        for arguments in (('plan',), ('apply',), ('check',), ('--config-only',),
                          ('--config-only', '--package', 'editor')):
            with self.subTest(arguments=arguments):
                result = self.setup_rc(*arguments)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertNotIn('Setup: editor', result.stdout)
        self.assertFalse((self.home / '.setup').exists())

    def test_untracked_entry_is_not_executed(self) -> None:
        self.entry('editor', 'raise SystemExit(99)\n', tracked=False)
        result = self.setup_rc()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn('Setup: editor', result.stdout)

    def test_entry_failure_preserves_exit_status_and_stops_later_entries(self) -> None:
        self.entry('editor', 'raise SystemExit(23)\n')
        self.entry('later', "(Path.home() / 'later-ran').touch()\n")
        result = self.setup_rc()
        self.assertEqual(result.returncode, 23, result.stdout + result.stderr)
        self.assertIn('command failed (23)', result.stderr)
        self.assertNotIn('Setup completed successfully', result.stdout)
        self.assertFalse((self.home / 'later-ran').exists())

    def test_configuration_conflict_prevents_entry_execution(self) -> None:
        self.entry('editor', "(Path.home() / 'prepared').touch()\n")
        (self.home / '.editorrc').write_text('keep my edits')
        result = self.setup_rc()
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.home / 'prepared').exists())
        self.assertEqual((self.home / '.editorrc').read_text(), 'keep my edits')

    def test_unknown_or_hidden_package_fails_before_linking(self) -> None:
        for name in ('missing', '.setup'):
            with self.subTest(name=name):
                result = self.setup_rc('--package', name)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('Unknown packages', result.stderr)
                self.assertFalse((self.home / '.editorrc').exists())

    def test_setup_entries_do_not_share_mutable_process_state(self) -> None:
        self.entry('before-editor', "os.environ['HOME'] = 'incorrect-home'\n")
        self.entry('editor', "(Path.home() / 'prepared').write_text(os.environ['HOME'])\n")
        result = self.setup_rc()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual((self.home / 'prepared').read_text(), str(self.home))

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
        self.assertFalse(any('.config/nvim' in Path(link['target']).as_posix() for link in links))

    def test_conflicting_local_configuration_stops_setup(self) -> None:
        target = self.home / '.editorrc'
        target.write_text('local preference\n')
        result = self.setup_rc('--config-only')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Configuration conflict', result.stdout + result.stderr)
        self.assertNotIn('Setup completed successfully', result.stdout)
        self.assertEqual(target.read_text(), 'local preference\n')

    def test_github_credential_helper_is_shared_and_uses_path(self) -> None:
        for platform in ('linux', 'windows'):
            with self.subTest(platform=platform):
                home = self.root / platform
                result = self.setup_rc('apply', '--repo', str(self.checkout), '--home', str(home),
                                       '--platform', platform, '--package', 'git')
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                environment = dict(self.environment, HOME=str(home), USERPROFILE=str(home),
                                   GIT_CONFIG_GLOBAL=str(home / '.gitconfig'))
                for domain in ('github.com', 'gist.github.com'):
                    helper = subprocess.check_output(
                        ['git', 'config', '--global', '--get-urlmatch', 'credential.helper',
                         'https://' + domain], env=environment, text=True)
                    self.assertEqual(helper.strip(), '!gh auth git-credential')

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

    def test_selected_package_prepares_and_links_its_dependencies_first(self) -> None:
        self.entry('runtime', "(Path.home() / 'runtime-ready').touch()\n")
        self.entry('editor', "assert (Path.home() / 'runtime-ready').exists()\n")
        requirement = self.repo / 'editor/.setup/requirements.py'
        requirement.write_text("DEPENDENCIES = ('runtime',)\n")
        self.git('add', '-f', '--', str(requirement))
        result = self.setup_rc('--package', 'editor', '--no-install')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertLess(result.stdout.index('Setup: runtime'), result.stdout.index('Setup: editor'))

    def test_prerequisite_inventory_is_read_only_and_no_install_rejects_missing_tools(self) -> None:
        self.entry('editor', "(Path.home() / 'prepared').touch()\n")
        requirement = self.repo / 'editor/.setup/requirements.py'
        requirement.write_text("from system import Package\nPACKAGES = [Package('rc-test-nonexistent', ('rc-test-nonexistent',), 'Fixture.Missing')]\n")
        self.git('add', '-f', '--', str(requirement))
        result = self.setup_rc('prerequisites', '--json')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(json.loads(result.stdout)[0]['command'], 'rc-test-nonexistent')
        result = self.setup_rc('--no-install')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Missing native requirements', result.stderr)
        self.assertFalse((self.home / '.editorrc').exists())
        self.assertFalse((self.home / 'prepared').exists())
        self.assertEqual(self.setup_rc('--config-only').returncode, 0)

    def test_skipping_package_entry_still_links_its_settings(self) -> None:
        self.entry('editor', 'raise SystemExit(99)\n')
        result = self.setup_rc('--skip-setup', 'editor')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue((self.home / '.editorrc').is_symlink())

    @unittest.skipUnless(os.name == 'nt', 'Windows application launch')
    def test_package_launch_has_real_redirected_application_directories(self) -> None:
        self.entry('editor', "assert Path(os.environ['APPDATA']).is_dir()\nassert Path(os.environ['LOCALAPPDATA']).is_dir()\n")
        result = self.setup_rc('--package', 'editor')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == '__main__':
    unittest.main()
