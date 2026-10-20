import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest


class SettingsFixture(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix='claude-settings-')
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name).resolve()
        self.checkout = Path(__file__).resolve().parents[3]
        self.repo = self.root / 'rc_files'
        shutil.copytree(self.checkout / 'claude', self.repo / 'claude',
                        ignore=shutil.ignore_patterns('.claude', '__pycache__', '*.pyc', '*.swp', '*.swo'))
        self.entry = self.repo / 'claude/.setup'
        self.home = self.root / "Someone's home"
        self.home.mkdir()
        self.settings = self.home / '.claude/settings.json'
        self.key = self.home / 'vault/claude_key.txt'
        self.key.parent.mkdir()
        self.secret = 'private-' + self.root.name
        self.key.write_text(self.secret + '\n')
        self.state = self.home / '.claude.json'
        self.state.write_text('{"projects":{"keep":{}},"machineID":"keep"}')
        self.environment = dict(os.environ, HOME=str(self.home), USERPROFILE=str(self.home),
                                GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM='1',
                                PYTHONPATH=str(self.checkout / '.setup'))
        for name in ('CLAUDE_KEY_FILE', 'CLAUDE_CONFIG_DIR', 'RC_SETUP_UPDATE',
                     'RC_SETUP_REDIRECTED', 'BACKUP_DIR'):
            self.environment.pop(name, None)
        if os.name == 'nt':
            for name, suffix in (('LOCALAPPDATA', 'Local'), ('APPDATA', 'Roaming')):
                directory = self.home / 'AppData' / suffix
                directory.mkdir(parents=True)
                self.environment[name] = str(directory)

    def setup_claude(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run([sys.executable, '-B', '-c', 'import runpy; from pathlib import Path; ' +
                               'runpy.run_path(' + repr(str(self.entry / '__main__.py')) + ')["setup"](Path.home())'], env=self.environment,
                              cwd=self.root, text=True, encoding='utf-8', capture_output=True)

    def prepared(self) -> dict[str, object]:
        result = self.setup_claude()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn(self.secret, result.stdout + result.stderr)
        return json.loads(self.settings.read_text())

    def write_settings(self, settings: dict[str, object]) -> None:
        self.settings.parent.mkdir(exist_ok=True)
        self.settings.write_text(json.dumps(settings), encoding='utf-8')


class SettingsTests(SettingsFixture):
    def test_entry_installs_claude_before_preparing_settings(self) -> None:
        modules = self.root / 'modules'
        modules.mkdir()
        (modules / 'npm.py').write_text('''
import json
import os
from pathlib import Path

def install(package, command):
    home = Path.home()
    assert not (home / '.claude/settings.json').exists()
    (home / 'installation.json').write_text(json.dumps([package, command]))
    if os.environ.get('FAIL_INSTALL') == '1':
        raise OSError('fixture installation failed')
''')
        environment = dict(self.environment, PYTHONPATH=str(modules))
        for fail in ('1', '0'):
            with self.subTest(fail=fail):
                result = subprocess.run([sys.executable, '-B', str(self.entry)],
                                        env=dict(environment, FAIL_INSTALL=fail),
                                        text=True, capture_output=True)
                self.assertEqual(json.loads((self.home / 'installation.json').read_text()),
                                 ['@anthropic-ai/claude-code', 'claude'])
                self.assertEqual(result.returncode, int(fail), result.stdout + result.stderr)
                self.assertEqual(self.settings.exists(), fail == '0')
                self.assertNotIn(self.secret, result.stdout + result.stderr)

    def test_fresh_setup_generates_private_settings_and_leaves_state_and_sources_unchanged(self) -> None:
        before = self.state.read_bytes(), self.state.stat().st_mtime_ns
        template = self.entry / 'settings.json.template'
        source = template.read_bytes()
        settings = self.prepared()
        self.assertEqual(settings['env']['ANTHROPIC_CUSTOM_HEADERS'], 'Ocp-Apim-Subscription-Key: ' + self.secret)
        self.assertEqual(settings['env']['ANTHROPIC_API_KEY'], 'dummy')
        self.assertFalse(self.settings.is_symlink())
        self.assertEqual((self.state.read_bytes(), self.state.stat().st_mtime_ns), before)
        self.assertEqual(template.read_bytes(), source)
        self.assertFalse(any(self.secret.encode() in path.read_bytes() for path in self.repo.rglob('*') if path.is_file()))

    def test_ordinary_rerun_keeps_local_preferences_format_and_timestamp(self) -> None:
        settings = self.prepared()
        settings['env']['CLAUDE_CODE_EFFORT_LEVEL'] = 'local-choice'
        settings['custom'] = {'preserved': True}
        self.write_settings(settings)
        before = self.settings.read_bytes(), self.settings.stat().st_mtime_ns
        self.prepared()
        self.assertEqual((self.settings.read_bytes(), self.settings.stat().st_mtime_ns), before)

    def test_key_replacement_only_takes_effect_when_setup_runs(self) -> None:
        settings = self.prepared()
        settings['env']['ANTHROPIC_CUSTOM_HEADERS'] += '\nX-Route: keep'
        self.write_settings(settings)
        self.key.write_text('replacement-' + self.secret)
        self.assertIn(self.secret, self.settings.read_text())
        self.assertNotIn('replacement-', self.settings.read_text())
        settings = self.prepared()
        self.assertEqual(settings['env']['ANTHROPIC_CUSTOM_HEADERS'],
                         'X-Route: keep\nOcp-Apim-Subscription-Key: replacement-' + self.secret)

    def test_missing_key_allows_setup_and_preserves_existing_credentials(self) -> None:
        self.key.unlink()
        self.assertNotIn('ANTHROPIC_CUSTOM_HEADERS', self.prepared()['env'])
        self.key.write_text(self.secret)
        self.prepared()
        self.key.unlink()
        before = self.settings.read_bytes(), self.settings.stat().st_mtime_ns
        self.prepared()
        self.assertEqual((self.settings.read_bytes(), self.settings.stat().st_mtime_ns), before)

    def test_update_refreshes_template_preferences_and_preserves_local_extras(self) -> None:
        self.write_settings({'env': {'CLAUDE_CODE_EFFORT_LEVEL': 'local', 'LOCAL_ONLY': 'keep'}, 'custom': True})
        self.assertEqual(self.prepared()['env']['CLAUDE_CODE_EFFORT_LEVEL'], 'local')
        self.environment['RC_SETUP_UPDATE'] = '1'
        settings = self.prepared()
        self.assertEqual(settings['env']['CLAUDE_CODE_EFFORT_LEVEL'], 'max')
        self.assertEqual(settings['env']['LOCAL_ONLY'], 'keep')
        self.assertTrue(settings['custom'])

    def test_invalid_key_cannot_modify_existing_settings_or_leak_its_value(self) -> None:
        self.prepared()
        before = self.settings.read_bytes(), self.settings.stat().st_mtime_ns
        for value in ('', 'invalid-secret\nInjected: header', 'invalid\x00secret', 'invalid secret', 'invalid-é-secret'):
            with self.subTest(value=repr(value)):
                self.key.write_text(value, encoding='utf-8')
                result = self.setup_claude()
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn('invalid-secret', result.stdout + result.stderr)
                self.assertEqual((self.settings.read_bytes(), self.settings.stat().st_mtime_ns), before)
                self.assertEqual(list(self.settings.parent.iterdir()), [self.settings])

    def test_invalid_settings_fail_without_rewriting_them(self) -> None:
        self.settings.parent.mkdir()
        for value in ('{broken', '[]', '{"env":[]}', '{"env":{"ANTHROPIC_CUSTOM_HEADERS":[]}}'):
            with self.subTest(value=value):
                self.settings.write_text(value)
                result = self.setup_claude()
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(self.settings.read_text(), value)
                self.assertNotIn(self.secret, result.stdout + result.stderr)

    def test_source_owned_settings_link_is_detached_before_secrets_are_written(self) -> None:
        source = self.repo / 'claude/old-settings.json'
        source.write_text('{"local":"keep"}')
        self.settings.parent.mkdir()
        self.settings.symlink_to(source)
        self.assertEqual(self.prepared()['local'], 'keep')
        self.assertFalse(self.settings.is_symlink())
        self.assertEqual(source.read_text(), '{"local":"keep"}')

    def test_unrelated_settings_link_and_git_owned_directory_are_rejected(self) -> None:
        source = self.root / 'unrelated.json'
        source.write_text('{}')
        self.settings.parent.mkdir()
        self.settings.symlink_to(source)
        result = self.setup_claude()
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(self.settings.is_symlink())
        self.assertEqual(source.read_text(), '{}')
        self.environment['CLAUDE_CONFIG_DIR'] = str(self.repo / 'private')
        result = self.setup_claude()
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.repo / 'private').exists())

    def test_overrides_and_bom_key_are_supported(self) -> None:
        directory = self.home / 'custom Claude'
        key = self.home / 'custom key.txt'
        key.write_text(self.secret + '\r\n', encoding='utf-8-sig')
        self.environment.update(CLAUDE_CONFIG_DIR=str(directory), CLAUDE_KEY_FILE=str(key))
        self.settings = directory / 'settings.json'
        self.prepared()
        self.assertTrue(self.settings.is_file())

    def test_generated_file_permissions_are_private(self) -> None:
        self.prepared()
        if os.name == 'nt':
            self.environment['FIXTURE_SETTINGS'] = str(self.settings)
            command = '''$ErrorActionPreference = 'Stop'
$acl = [IO.File]::GetAccessControl($env:FIXTURE_SETTINGS)
$acl.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier]) | ForEach-Object { $_.IdentityReference.Value }
[Security.Principal.WindowsIdentity]::GetCurrent().User.Value'''
            result = subprocess.run(['powershell.exe', '-NoProfile', '-Command', command],
                                    env=self.environment, text=True, capture_output=True, check=True)
            entries = result.stdout.splitlines()
            self.assertEqual(set(entries[:-1]), {entries[-1], 'S-1-5-18', 'S-1-5-32-544'})
        else:
            self.assertEqual(stat.S_IMODE(self.settings.stat().st_mode), 0o600)


class DeploymentTests(SettingsFixture):
    def git(self, *arguments: str) -> None:
        subprocess.run(['git', '-C', str(self.repo), *arguments], check=True,
                       env=self.environment, capture_output=True)

    def test_generic_setup_and_config_only_have_distinct_roles(self) -> None:
        shutil.copytree(self.checkout / 'node', self.repo / 'node', ignore=shutil.ignore_patterns('__pycache__', '*.pyc'))
        binaries = self.home / '.local/bin'
        binaries.mkdir(parents=True)
        cli = binaries / ('claude.cmd' if os.name == 'nt' else 'claude')
        cli.write_text('@echo off\nexit /b 0\n' if os.name == 'nt' else '#!/bin/sh\nexit 0\n')
        cli.chmod(0o755)
        self.environment['PATH'] = str(binaries) + os.pathsep + self.environment['PATH']
        self.git('init', '-q')
        self.git('add', '-f', '--all')
        command = [sys.executable, '-B', str(self.checkout / '.setup'), '--repo', str(self.repo),
                   '--home', str(self.home), '--package', 'claude']
        result = subprocess.run(command + ['--config-only'], env=self.environment, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse(self.settings.exists())
        for _ in range(2):
            result = subprocess.run(command, env=self.environment, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertTrue(self.settings.is_file())
            self.assertFalse(self.settings.is_symlink())
        self.assertEqual(list(self.settings.parent.iterdir()), [self.settings])
        self.assertFalse((self.home / 'README.md').exists())
        self.assertFalse((self.home / '.setup').exists())
        self.assertEqual(self.state.read_text(), '{"projects":{"keep":{}},"machineID":"keep"}')

    def test_redirected_setup_refuses_paths_outside_its_home(self) -> None:
        self.environment.update(RC_SETUP_REDIRECTED='1', CLAUDE_KEY_FILE=str(self.root / 'outside-key'))
        result = self.setup_claude()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('inside its test home', result.stderr)
        self.assertFalse(self.settings.exists())

    def test_full_migration_keeps_private_settings_and_retires_the_old_launcher_link(self) -> None:
        self.prepared()
        before = self.settings.read_bytes(), self.settings.stat().st_mtime_ns
        instructions = self.repo / 'agents/.claude/CLAUDE.md'
        instructions.parent.mkdir(parents=True)
        instructions.write_text('tracked instructions')
        shutil.copytree(self.checkout / 'node', self.repo / 'node', ignore=shutil.ignore_patterns('__pycache__', '*.pyc'))
        binaries = self.home / '.local/bin'
        binaries.mkdir(parents=True)
        cli = binaries / ('claude.cmd' if os.name == 'nt' else 'claude')
        cli.write_text('@echo off\nexit /b 0\n' if os.name == 'nt' else '#!/bin/sh\nexit 0\n')
        cli.chmod(0o755)
        self.environment['PATH'] = str(binaries) + os.pathsep + self.environment['PATH']
        self.git('init', '-q')
        self.git('add', '-f', '--all')
        source = self.repo / 'claude/old-launch.py'
        source.write_text('obsolete launcher')
        launcher = self.settings.parent / 'launch.py'
        launcher.symlink_to(source)
        result = subprocess.run(
            [sys.executable, '-B', str(self.checkout / '.setup'), '--repo', str(self.repo),
             '--home', str(self.home), '--config-only'], env=self.environment, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse(os.path.lexists(launcher))
        self.assertEqual((self.settings.read_bytes(), self.settings.stat().st_mtime_ns), before)

    @unittest.skipUnless(sys.platform == 'linux' and os.environ.get('SCRIPTS_ROOT'),
                         'Set SCRIPTS_ROOT for the Linux credential-setup integration check')
    def test_container_credential_setup_generates_settings_after_the_vault_is_available(self) -> None:
        scripts = Path(os.environ['SCRIPTS_ROOT'])
        fixture = self.root / 'scripts/setup/linux'
        (fixture / 'credentials').mkdir(parents=True)
        (fixture / 'lib').mkdir()
        shutil.copy2(scripts / 'setup/linux/credentials/activate.sh', fixture / 'credentials/activate.sh')
        for name in ('sync.sh', 'vault.sh'):
            (fixture / 'credentials' / name).write_text('printf "%s\\n" "$*" >> "$HOME/credential-calls"\n')
        (fixture / 'lib/find_persistent_root.sh').write_text('find_persistent_root() { :; }\n')
        (fixture / 'lib/fix_hostname.sh').write_text('fix_hostname() { :; }\n')
        (self.home / '.ssh').mkdir()
        (self.home / '.ssh/id_ed25519').touch()
        (self.repo / '.setup').mkdir()
        for name in ('__main__.py', 'context.py', 'links.py'):
            shutil.copy2(self.checkout / '.setup' / name, self.repo / '.setup' / name)
        (self.home / 'rc_files').symlink_to(self.repo, target_is_directory=True)
        shutil.copytree(self.checkout / 'node', self.repo / 'node', ignore=shutil.ignore_patterns('__pycache__', '*.pyc'))
        binaries = self.home / '.local/bin'
        binaries.mkdir(parents=True)
        cli = binaries / ('claude.cmd' if os.name == 'nt' else 'claude')
        cli.write_text('@echo off\nexit /b 0\n' if os.name == 'nt' else '#!/bin/sh\nexit 0\n')
        cli.chmod(0o755)
        self.environment['PATH'] = str(binaries) + os.pathsep + self.environment['PATH']
        self.git('init', '-q')
        self.git('add', '-f', '--all')
        for value in (self.secret, 'replacement-' + self.secret):
            self.key.write_text(value)
            result = subprocess.run(['bash', str(fixture / 'credentials/activate.sh')], env=self.environment,
                                    cwd=self.root, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(json.loads(self.settings.read_text())['env']['ANTHROPIC_CUSTOM_HEADERS'],
                             'Ocp-Apim-Subscription-Key: ' + value)
            self.assertNotIn(value, result.stdout + result.stderr)
        self.assertEqual(self.state.read_text(), '{"projects":{"keep":{}},"machineID":"keep"}')
        self.assertEqual((self.home / 'credential-calls').read_text().splitlines().count('docker'), 2)


if __name__ == '__main__':
    unittest.main()
