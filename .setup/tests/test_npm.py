import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import npm


class NpmTests(unittest.TestCase):
    def setUp(self) -> None:
        redirected = patch.dict(os.environ, RC_SETUP_REDIRECTED='1')
        redirected.start()
        self.addCleanup(redirected.stop)

    def test_existing_cli_skips_redundant_installation(self) -> None:
        with patch.dict(os.environ, RC_SETUP_UPDATE='0'), \
                patch.object(npm.shutil, 'which', return_value='existing-cli'), \
                patch.object(npm.subprocess, 'run') as run:
            npm.install('@fixture/cli', 'fixture')
            run.assert_not_called()

    def test_no_install_never_installs_or_updates_a_cli(self) -> None:
        with patch.dict(os.environ, RC_SETUP_INSTALL='0', RC_SETUP_UPDATE='1'), \
                patch.object(npm.subprocess, 'run') as run:
            with patch.object(npm.shutil, 'which', return_value='existing-cli'):
                npm.install('@fixture/cli', 'fixture')
            with patch.object(npm.shutil, 'which', return_value=None):
                with self.assertRaisesRegex(ValueError, '--no-install cannot install'):
                    npm.install('@fixture/cli', 'fixture')
            run.assert_not_called()

    def test_existing_cli_from_another_installer_keeps_its_own_updater(self) -> None:
        with patch.dict(os.environ, RC_SETUP_UPDATE='1'), \
                patch.object(npm.shutil, 'which', return_value='/another/installer/cli'), \
                patch.object(npm.subprocess, 'run') as run:
            npm.install('@fixture/cli', 'fixture')
            run.assert_not_called()

    def test_missing_cli_installs_latest_into_the_selected_home_and_verifies_files(self) -> None:
        with tempfile.TemporaryDirectory(prefix='rc-npm-') as temporary:
            home = Path(temporary).resolve()
            prefix = home / 'npm' if os.name == 'nt' else home / '.local'

            def install(command: list[str], **kwargs: object) -> None:
                if command[-1] == '--version':
                    return
                package = prefix / ('node_modules' if os.name == 'nt' else 'lib/node_modules') / '@fixture/cli/package.json'
                package.parent.mkdir(parents=True)
                package.write_text('{"version":"1.2.3"}')
                executable = prefix / 'fixture.cmd' if os.name == 'nt' else prefix / 'bin/fixture'
                executable.parent.mkdir(parents=True, exist_ok=True)
                executable.touch()

            with patch.dict(os.environ, HOME=str(home), USERPROFILE=str(home), APPDATA=str(home), RC_SETUP_INSTALL='1'), \
                    patch.object(npm.shutil, 'which', side_effect=[None, 'npm']), \
                    patch.object(npm, 'persist_path') as persist, \
                    patch.object(npm.subprocess, 'run', side_effect=install) as run:
                npm.install('@fixture/cli', 'fixture')
            self.assertEqual(run.call_args_list[0].args[0], ['npm', 'install', '--global', '--prefix', str(prefix), '@fixture/cli@latest'])
            self.assertEqual(run.call_args_list[1].args[0][-1], '--version')
            persist.assert_called_once_with(prefix if os.name == 'nt' else prefix / 'bin')

    @unittest.skipUnless(os.name == 'nt', 'Windows shared npm commands')
    def test_windows_uses_machine_requirement_even_with_user_command(self) -> None:
        with patch.dict(os.environ, RC_SETUP_REDIRECTED='0', RC_SETUP_INSTALL='1'), \
                patch.object(npm.shutil, 'which', return_value='user-cli'), \
                patch.object(npm, 'installed', return_value=False), \
                patch.object(npm, 'install_system') as install:
            npm.install('@fixture/cli', 'fixture')
            install.assert_called_once_with([npm.Package('fixture', npm='@fixture/cli')], allow=True)

    @unittest.skipUnless(os.name == 'nt', 'Windows shared npm commands')
    def test_user_configuration_never_updates_an_installed_machine_cli(self) -> None:
        with patch.dict(os.environ, RC_SETUP_REDIRECTED='0', RC_SETUP_UPDATE='1'), \
                patch.object(npm, 'installed', return_value=True), \
                patch.object(npm, 'install_system') as install:
            npm.install('@fixture/cli', 'fixture')
            install.assert_not_called()


if __name__ == '__main__':
    unittest.main()
