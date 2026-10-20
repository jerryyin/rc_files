import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


entry = Path(__file__).resolve().parents[1] / '__main__.py'
sys.path.insert(0, str(entry.parents[2] / '.setup'))
import links
import packages

spec = importlib.util.spec_from_file_location('mux_setup', entry)
mux = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mux)


class MuxSetupTests(unittest.TestCase):
    def test_selected_mux_includes_its_configured_shell_before_plugin_setup(self) -> None:
        repo = entry.parents[2]
        for platform, shell in (('linux', 'zsh'), ('windows', 'powershell')):
            with self.subTest(platform=platform):
                selected = packages.discover(repo, links.tracked_files(repo), ['tmux'], platform)
                self.assertIn(shell, selected.names)
                self.assertLess(selected.names.index(shell), selected.names.index('tmux'))

    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix='rc-mux-')
        self.addCleanup(temporary.cleanup)
        self.home = Path(temporary.name).resolve() / "Someone's home"
        self.home.mkdir()
        self.calls = []

    def record_run(self, command, **kwargs):
        environment = dict(kwargs.get('env', os.environ))
        self.calls.append((command, environment))
        return subprocess.CompletedProcess(command, 0)

    def test_linux_setup_uses_an_isolated_server_and_updates_only_when_requested(self) -> None:
        for update in (False, True):
            with self.subTest(update=update), patch.object(mux.shutil, 'which', return_value='tmux'), \
                    patch.object(mux.subprocess, 'run', side_effect=self.record_run), \
                    patch.object(mux.subprocess, 'check_output', return_value='/fixture/socket,42,0\n'), \
                    patch.dict(os.environ, TMUX='live-session', TMUX_PANE='%1', RC_SETUP_REDIRECTED='1'):
                self.calls.clear()
                mux.linux_plugins(self.home, update)
                commands = [command for command, _ in self.calls]
                self.assertEqual(commands[0][:2], ['git', 'clone'])
                start, environment = self.calls[1]
                self.assertEqual(start[1], '-L')
                self.assertTrue(start[2].startswith('rc-setup-'))
                self.assertEqual(start[3:5], ['-f', str(self.home / '.tmux.conf')])
                self.assertNotIn('TMUX', environment)
                self.assertNotIn('TMUX_PANE', environment)
                install = next((command, env) for command, env in self.calls if command[0].endswith('install_plugins'))
                self.assertEqual(install[1]['TMUX'], '/fixture/socket,42,0')
                self.assertEqual(any(command[0].endswith('update_plugins') for command in commands), update)
                self.assertEqual(commands[-1], [*start[:3], 'kill-server'])

    def test_installed_tpm_is_retained_unless_update_is_requested(self) -> None:
        tpm = self.home / '.tmux/plugins/tpm'
        tpm.mkdir(parents=True)
        for update in (False, True):
            with self.subTest(update=update), patch.object(mux.shutil, 'which', return_value='tmux'), \
                    patch.object(mux.subprocess, 'run', side_effect=self.record_run), \
                    patch.object(mux.subprocess, 'check_output', return_value='/socket,42,0'), \
                    patch.dict(os.environ, RC_SETUP_REDIRECTED='1'):
                self.calls.clear()
                mux.linux_plugins(self.home, update)
                git = [command for command, _ in self.calls if command[0] == 'git']
                self.assertEqual(git, [['git', '-C', str(tpm), 'pull', '--ff-only']] if update else [])

    def test_linux_failure_kills_only_the_setup_server(self) -> None:
        def fail_install(command, **kwargs):
            result = self.record_run(command, **kwargs)
            if command[0].endswith('install_plugins'):
                raise subprocess.CalledProcessError(7, command)
            return result

        with patch.object(mux.shutil, 'which', return_value='tmux'), \
                patch.object(mux.subprocess, 'run', side_effect=fail_install), \
                patch.object(mux.subprocess, 'check_output', return_value='/socket,42,0'):
            with self.assertRaises(subprocess.CalledProcessError):
                mux.linux_plugins(self.home, False)
        self.assertEqual(self.calls[-1][0][-1], 'kill-server')
        self.assertEqual(self.calls[-1][0][:3], self.calls[1][0][:3])

    def test_redirected_home_never_reloads_the_live_tmux_server(self) -> None:
        (self.home / '.tmux/plugins/tpm').mkdir(parents=True)
        for redirected in ('0', '1'):
            with self.subTest(redirected=redirected), patch.object(mux.Path, 'home', return_value=self.home), \
                    patch.object(mux.shutil, 'which', return_value='tmux'), \
                    patch.object(mux.subprocess, 'run', side_effect=self.record_run), \
                    patch.object(mux.subprocess, 'check_output', return_value='/socket,42,0'), \
                    patch.dict(os.environ, RC_SETUP_REDIRECTED=redirected):
                self.calls.clear()
                mux.linux_plugins(self.home, False)
                commands = [command for command, _ in self.calls]
                self.assertEqual(['tmux', 'has-session'] in commands, redirected == '0')
                self.assertEqual(['tmux', 'source-file', str(self.home / '.tmux.conf')] in commands,
                                 redirected == '0')

    def test_windows_setup_uses_its_own_helper_and_does_not_reinstall_ppm(self) -> None:
        manager = self.home / '.psmux/plugins/ppm/ppm.ps1'
        manager.parent.mkdir(parents=True)
        manager.write_text('fixture')
        with patch.object(mux.shutil, 'which', side_effect=lambda name: name), \
                patch.object(mux.subprocess, 'run', side_effect=self.record_run), \
                patch.dict(os.environ, PSMUX_DATA_DIR='live-server', PSMUX_SESSION='live-session', TMUX='live-tmux'):
            mux.windows_plugins(self.home, False)
        start, environment = self.calls[0]
        self.assertEqual(start[:3], ['psmux', '-f', str(self.home / '.psmux.conf')])
        self.assertNotEqual(environment['PSMUX_DATA_DIR'], 'live-server')
        self.assertEqual(environment['PSMUX_NO_WARM'], '1')
        self.assertNotIn('TMUX', environment)
        helper = self.calls[1][0]
        self.assertEqual(helper[:3], ['pwsh', '-NoProfile', '-File'])
        self.assertEqual(Path(helper[3]), entry.with_name('psmux-plugins.ps1'))
        self.assertNotIn('-Update', helper)
        self.assertEqual(self.calls[-1][0], ['psmux', 'kill-server'])
        self.assertEqual(self.calls[-1][1]['PSMUX_DATA_DIR'], environment['PSMUX_DATA_DIR'])

    def test_windows_update_refreshes_manager_and_passes_update_to_ppm(self) -> None:
        cache = self.home / '.psmux/plugin-source/ppm'
        cache.mkdir(parents=True)
        (cache / 'ppm.ps1').write_text('latest manager')
        with patch.object(mux.shutil, 'which', side_effect=lambda name: name), \
                patch.object(mux.subprocess, 'run', side_effect=self.record_run):
            mux.windows_plugins(self.home, True)
        self.assertEqual(self.calls[0][0], ['git', '-C', str(cache.parent), 'pull', '--ff-only'])
        self.assertEqual((self.home / '.psmux/plugins/ppm/ppm.ps1').read_text(), 'latest manager')
        self.assertEqual(self.calls[2][0][-1], '-Update')

    def test_windows_failure_cleans_up_the_isolated_server(self) -> None:
        manager = self.home / '.psmux/plugins/ppm/ppm.ps1'
        manager.parent.mkdir(parents=True)
        manager.write_text('fixture')

        def fail_helper(command, **kwargs):
            result = self.record_run(command, **kwargs)
            if command[0] == 'pwsh':
                raise subprocess.CalledProcessError(9, command)
            return result

        with patch.object(mux.shutil, 'which', side_effect=lambda name: name), \
                patch.object(mux.subprocess, 'run', side_effect=fail_helper):
            with self.assertRaises(subprocess.CalledProcessError):
                mux.windows_plugins(self.home, False)
        self.assertEqual(self.calls[-1][0], ['psmux', 'kill-server'])
        self.assertEqual(self.calls[-1][1]['PSMUX_DATA_DIR'], self.calls[0][1]['PSMUX_DATA_DIR'])

    def test_missing_native_tools_are_errors(self) -> None:
        with patch.object(mux.shutil, 'which', return_value=None):
            with self.assertRaisesRegex(ValueError, 'tmux is not installed'):
                mux.linux_plugins(self.home, False)
            with self.assertRaisesRegex(ValueError, 'PowerShell 7 are required'):
                mux.windows_plugins(self.home, False)


if __name__ == '__main__':
    unittest.main()
