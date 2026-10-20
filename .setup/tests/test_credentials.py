import base64
import json
import os
from pathlib import Path
import runpy
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import private


class CredentialFixture(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix='rc-credentials-')
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name).resolve()
        self.repo = self.root / 'configuration'
        self.home = self.root / "Someone's home"
        self.home.mkdir()
        self.repo.mkdir()
        self.vault = self.home / 'vault'
        self.vault.mkdir()
        self.checkout = Path(__file__).resolve().parents[2]
        self.environment = dict(os.environ, GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM='1',
                                HOME=str(self.home), USERPROFILE=str(self.home))
        for name in ('CLAUDE_CONFIG_DIR', 'CLAUDE_KEY_FILE', 'DOCKER_CONFIG', 'DOCKER_AUTH_FILE',
                     'GH_CONFIG_DIR', 'GH_JERRYYIN_KEY_FILE', 'GH_AMDENG_KEY_FILE', 'GIST_CONFIG',
                     'GIST_KEY_FILE', 'ARTIFACTORY_KEY_FILE', 'CODEX_HOME', 'NETRC_HOST', 'NETRC_LOGIN'):
            self.environment.pop(name, None)
        self.git('init', '-q')

    def git(self, *arguments: str) -> None:
        subprocess.run(['git', '-C', str(self.repo), *arguments], check=True,
                       env=self.environment, capture_output=True)

    def write(self, name: str, text: str) -> Path:
        path = self.repo / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding='utf-8')
        self.git('add', '-f', '--', name)
        return path

    def copy_package(self, name: str) -> None:
        files = subprocess.check_output(['git', '-C', str(self.checkout), 'ls-files', '-z', '--', name]).decode().split('\0')
        for relative in filter(None, files):
            target = self.repo / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(self.checkout / relative, target)
        self.git('add', '-f', '--', name)

    def invoke(self, *arguments: str, action: str = 'credentials') -> subprocess.CompletedProcess[str]:
        return subprocess.run([sys.executable, '-B', str(self.checkout / '.setup'), action,
                               '--repo', str(self.repo), '--home', str(self.home), *arguments],
                              env=self.environment, text=True, capture_output=True)

    def ok(self, *arguments: str, action: str = 'credentials') -> str:
        result = self.invoke(*arguments, action=action)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout + result.stderr


class PhaseTests(CredentialFixture):
    def test_credentials_only_runs_tracked_selected_hooks_without_installing_or_linking(self) -> None:
        self.write('app/.public', 'public')
        self.write('app/.setup/requirements.py', "raise RuntimeError('must not inspect requirements')")
        self.write('app/.setup/__main__.py', 'raise SystemExit(91)')
        self.write('app/.setup/credentials.py', '''import os
from pathlib import Path
assert os.environ['RC_SETUP_INSTALL'] == '0'
assert not (Path.home() / '.public').exists()
(Path.home() / 'hook').write_text(os.environ['RC_CREDENTIALS_VAULT'])
''')
        self.write('other/.setup/credentials.py', 'raise SystemExit(92)')
        self.ok('--package', 'app', '--vault', str(self.vault))
        self.assertEqual((self.home / 'hook').read_text(), str(self.vault))
        self.assertFalse((self.home / '.public').exists())

    def test_setup_and_configuration_never_run_credentials_even_with_a_vault(self) -> None:
        self.write('app/.public', 'public')
        self.write('app/.setup/credentials.py', 'raise SystemExit(99)')
        self.ok(action='setup')
        self.ok('--config-only', action='setup')
        self.assertEqual((self.home / '.public').read_text(), 'public')

    def test_invalid_phase_options_and_unknown_packages_fail(self) -> None:
        self.write('app/.public', 'public')
        for args in (('--package', 'missing'), ('--config-only',), ('--save',)):
            self.assertNotEqual(self.invoke(*args).returncode, 0)
        self.assertNotEqual(self.invoke('--vault', str(self.vault), action='setup').returncode, 0)

    def test_untracked_hook_is_ignored(self) -> None:
        self.write('app/.public', 'public')
        hook = self.repo / 'app/.setup/credentials.py'
        hook.parent.mkdir()
        hook.write_text('raise SystemExit(99)')
        self.ok()
        self.assertFalse((self.home / '.public').exists())

    def test_failure_stops_later_hooks_and_preserves_status(self) -> None:
        self.write('a/.setup/credentials.py', 'raise SystemExit(23)')
        self.write('b/.setup/credentials.py', 'raise SystemExit(24)')
        result = self.invoke()
        self.assertEqual(result.returncode, 23)
        self.assertNotIn('Credentials: b', result.stdout)


class ApplicationTests(CredentialFixture):
    def test_missing_vault_changes_nothing_and_never_installs(self) -> None:
        for name in ('claude', 'docker', 'gh', 'gist', 'artifactory', 'codex', 'vim', 'git'):
            self.copy_package(name)
        self.vault.rmdir()
        self.ok()
        self.assertEqual(list(self.home.iterdir()), [])

    def test_docker_rotation_preserves_other_settings_and_invalid_input(self) -> None:
        self.copy_package('docker')
        path = self.home / '.docker/config.json'
        path.parent.mkdir()
        path.write_text(json.dumps({'currentContext': 'keep', 'auths': {
            'other': {'auth': 'keep'}, 'mkmhub.amd.com': {'custom': 'keep'}}}))
        secret = self.vault / 'docker_mkmhub_auth.txt'
        for password in ('first:password', 'second'):
            encoded = base64.b64encode(('fixture:' + password).encode()).decode()
            secret.write_text(encoded)
            output = self.ok()
            self.assertNotIn(encoded, output)
            self.assertNotIn(password, output)
            config = json.loads(path.read_text())
            self.assertEqual(config['auths']['mkmhub.amd.com'], {'custom': 'keep', 'auth': encoded})
            self.assertEqual(config['auths']['other']['auth'], 'keep')
            self.assertEqual(config['currentContext'], 'keep')
            before = path.read_bytes(), path.stat().st_mtime_ns
            self.ok()
            self.assertEqual((path.read_bytes(), path.stat().st_mtime_ns), before)
        for bad in ('secret-not-base64', base64.b64encode(b'bad\nuser:secret').decode()):
            secret.write_text(bad)
            result = self.invoke()
            self.assertNotEqual(result.returncode, 0)
            self.assertNotIn(bad, result.stdout + result.stderr)
            self.assertEqual((path.read_bytes(), path.stat().st_mtime_ns), before)
        secret.unlink()
        self.ok()
        self.assertEqual((path.read_bytes(), path.stat().st_mtime_ns), before)

    def test_docker_bad_existing_config_is_not_overwritten(self) -> None:
        self.copy_package('docker')
        (self.vault / 'docker_mkmhub_auth.txt').write_text(base64.b64encode(b'fixture:password').decode())
        path = self.home / '.docker/config.json'
        path.parent.mkdir()
        for content in ('{"private-secret": invalid}', '[]', '{"auths": []}'):
            path.write_text(content)
            result = self.invoke()
            self.assertNotEqual(result.returncode, 0)
            self.assertNotIn('private-secret', result.stdout + result.stderr)
            self.assertEqual(path.read_text(), content)

    @unittest.skipIf(os.name == 'nt', 'Windows uses native GitHub login')
    def test_github_rotation_and_account_state(self) -> None:
        self.copy_package('gh')
        (self.vault / 'gh_token_jerryyin.txt').write_text('fixture-personal')
        secret = self.vault / 'gh_token_amdeng.txt'
        secret.write_text('fixture-work')
        self.ok()
        path = self.home / '.config/gh/hosts.yml'
        secret.write_text('fixture-rotated')
        self.ok()
        self.assertIn('fixture-rotated', path.read_text())
        path.write_text(path.read_text().replace('user: zhuoryin_amdeng', 'user: jerryyin'))
        before = path.read_bytes(), path.stat().st_mtime_ns
        secret.write_text('fixture-newest')
        self.assertIn('preserving local account state', self.ok())
        self.assertEqual((path.read_bytes(), path.stat().st_mtime_ns), before)
        self.ok('--update')
        self.assertIn('fixture-newest', path.read_text())

    @unittest.skipIf(os.name == 'nt', 'Linux container persistence')
    def test_gist_and_netrc_rotation_preserve_other_hosts_and_permissions(self) -> None:
        self.copy_package('gist')
        self.copy_package('artifactory')
        netrc = self.home / '.netrc'
        netrc.write_text('machine other login keep password keep\n')
        for token in ('fixture-first', 'fixture-second'):
            (self.vault / 'gh_token_jerryyin.txt').write_text(token)
            (self.vault / 'atlartifactory_token.txt').write_text(token)
            self.assertNotIn(token, self.ok())
            self.assertEqual((self.home / '.gist').read_text(), token + '\n')
            self.assertIn('machine other login keep password keep\n', netrc.read_text())
            self.assertEqual(netrc.read_text().count('# >>> vault:'), 1)
            self.assertIn('password ' + token, netrc.read_text())
            self.assertEqual(netrc.stat().st_mode & 0o777, 0o600)
            before = netrc.read_bytes(), netrc.stat().st_mtime_ns
            self.ok()
            self.assertEqual((netrc.read_bytes(), netrc.stat().st_mtime_ns), before)

    @unittest.skipIf(os.name == 'nt', 'Legacy Linux directory link')
    def test_codex_migrates_whole_directory_link_without_losing_persistent_data(self) -> None:
        self.copy_package('codex')
        instructions = self.write('agents/.codex/AGENTS.md', 'tracked instructions')
        stored = self.home / 'storage/.codex'
        stored.mkdir(parents=True)
        (stored / 'auth.json').write_text('{"fake":"auth"}')
        (stored / 'config.toml').write_text('local_preferences = true\n')
        (stored / 'sessions').mkdir()
        (stored / 'sessions/keep').write_text('old state')
        directory = self.home / '.codex'
        directory.symlink_to(stored, target_is_directory=True)
        self.ok('--persistent-root', str(stored.parent))
        self.assertFalse(directory.is_symlink())
        self.assertEqual((directory / 'AGENTS.md').resolve(), instructions)

        self.assertEqual((directory / 'config.toml').read_text(), 'local_preferences = true\n')
        self.assertEqual((directory / 'auth.json').resolve(), stored / 'auth.json')
        self.assertFalse((directory / 'sessions').exists())
        self.assertEqual((stored / 'sessions/keep').read_text(), 'old state')
        (directory / 'auth.json').unlink()
        (directory / 'auth.json').write_text('{"fake":"refreshed"}')
        self.ok('--persistent-root', str(stored.parent))
        self.assertEqual((directory / 'auth.json').read_text(), '{"fake":"refreshed"}')
        self.ok('--persistent-root', str(stored.parent), '--save')
        self.assertEqual((stored / 'auth.json').read_text(), '{"fake":"refreshed"}')
        self.assertEqual((directory / 'AGENTS.md').resolve(), instructions)

    @unittest.skipIf(os.name == 'nt', 'Linux login persistence')
    def test_private_files_and_copilot_login_round_trip(self) -> None:
        self.copy_package('git')
        self.copy_package('vim')
        storage = self.home / 'storage'
        for name, value in (('.git-credentials', 'fake-git-login'), ('.config/github-copilot/hosts.json', '{"fake":"copilot"}')):
            source = self.home / name
            source.parent.mkdir(parents=True, exist_ok=True)
            source.write_text(value)
        self.ok('--persistent-root', str(storage), '--save')
        for name in ('.git-credentials', '.config/github-copilot/hosts.json'):
            self.assertEqual((self.home / name).resolve(), storage / name)
            self.assertEqual((storage / name).stat().st_mode & 0o777, 0o600)
        self.ok('--persistent-root', str(storage))


class PrivateOperationTests(unittest.TestCase):
    def test_gist_native_requirement_matches_the_debian_executable(self) -> None:
        source = Path(__file__).resolve().parents[2] / 'gist/.setup/requirements.py'
        requirements = runpy.run_path(str(source), init_globals={'PLATFORM': 'linux'})['PACKAGES']
        self.assertEqual([(item.command, item.apt) for item in requirements], [('gist-paste', ('gist',))])
        self.assertEqual(runpy.run_path(str(source), init_globals={'PLATFORM': 'windows'})['PACKAGES'], [])

    def test_git_destinations_and_linked_parents_are_refused(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            repo = root / 'repo'
            (repo / '.git').mkdir(parents=True)
            for destination in (repo / 'secret', root / 'link/secret'):
                if destination.parent != repo:
                    destination.parent.symlink_to(repo, target_is_directory=True)
                with self.assertRaises(ValueError):
                    private.write(destination, 'fake-secret')
            self.assertFalse((repo / 'secret').exists())

    @unittest.skipUnless(os.name == 'nt', 'Windows file permissions')
    def test_private_writer_removes_existing_explicit_public_access(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / 'credential'
            path.write_text('fake-secret')
            subprocess.run(['icacls', str(path), '/grant', '*S-1-1-0:(R)'], check=True, capture_output=True)
            private.write(path, 'fake-secret')
            script = '''$acl = [IO.File]::GetAccessControl($env:RC_PRIVATE_PATH)
$acl.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier]) | ForEach-Object { $_.IdentityReference.Value }
[Security.Principal.WindowsIdentity]::GetCurrent().User.Value'''
            result = subprocess.check_output(['powershell.exe', '-NoProfile', '-Command', script],
                                              env=dict(os.environ, RC_PRIVATE_PATH=str(path)), text=True)
            identities = result.splitlines()
            self.assertEqual(set(identities[:-1]), {identities[-1], 'S-1-5-18', 'S-1-5-32-544'})

    def test_docker_helper_uses_stdin_and_never_falls_back_to_plaintext(self) -> None:
        module = runpy.run_path(str(Path(__file__).resolve().parents[2] / 'docker/.setup/credentials.py'))
        setup = module['helper_login']
        calls = []

        def invoke(arguments, text):
            calls.append((arguments, text))
            return subprocess.CompletedProcess(arguments, 0, '{}', 'secret diagnostic')

        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            with patch.dict(setup.__globals__, command=invoke), patch.object(shutil, 'which', side_effect=lambda name: name):
                setup('desktop', 'registry', 'fixture', 'test:password', directory)
            self.assertEqual(calls[-1][1], 'test:password\n')
            self.assertNotIn('test:password', calls[-1][0])
            self.assertIn('--password-stdin', calls[-1][0])
            self.assertIn(str(directory), calls[-1][0])
            self.assertFalse((directory / 'config.json').exists())
            calls.clear()
            credential = json.dumps({'Username': 'fixture', 'Secret': 'test:password'})
            with patch.dict(setup.__globals__, command=lambda args, text: subprocess.CompletedProcess(args, 0, credential)), patch.object(shutil, 'which', side_effect=lambda name: name):
                setup('desktop', 'registry', 'fixture', 'test:password', directory)
            self.assertEqual(calls, [])
            with patch.object(shutil, 'which', return_value=None):
                setup('desktop', 'registry', 'fixture', 'test:password', directory)
            self.assertFalse((directory / 'config.json').exists())


if __name__ == '__main__':
    unittest.main()
