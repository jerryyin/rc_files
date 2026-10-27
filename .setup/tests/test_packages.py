import os
from pathlib import Path
import runpy
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import MagicMock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import packages
import system


class RequirementTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix='rc-requirements-')
        self.addCleanup(temporary.cleanup)
        self.repo = Path(temporary.name)
        self.tracked: dict[str, str] = {}

    def requirements(self, name: str, text: str) -> None:
        path = self.repo / name / '.setup/requirements.py'
        path.parent.mkdir(parents=True)
        path.write_text(text)
        self.tracked[str(path.relative_to(self.repo)).replace('\\', '/')] = ''

    def test_dependencies_are_discovered_once_before_their_consumer(self) -> None:
        self.requirements('editor', "DEPENDENCIES = ('runtime', 'runtime')\n")
        self.requirements('runtime', "from system import Package\nPACKAGES = [Package('node', ('nodejs',), 'OpenJS.NodeJS.LTS')]\n")
        selection = packages.discover(self.repo, self.tracked, ['editor'], 'linux')
        self.assertEqual(selection.names, ['runtime', 'editor'])
        self.assertEqual(selection.requirements, [system.Package('node', ('nodejs',), 'OpenJS.NodeJS.LTS')])

    def test_untracked_requirements_are_not_executed(self) -> None:
        self.requirements('editor', "raise RuntimeError('untracked code')\n")
        self.tracked = {'editor/.editorrc': ''}
        self.assertEqual(packages.discover(self.repo, self.tracked, ['editor'], 'linux').requirements, [])

    def test_missing_and_circular_dependencies_fail(self) -> None:
        self.requirements('editor', "DEPENDENCIES = ('runtime',)\n")
        with self.assertRaisesRegex(ValueError, 'Unknown packages'):
            packages.discover(self.repo, self.tracked, ['editor'], 'linux')
        self.requirements('runtime', "DEPENDENCIES = ('editor',)\n")
        with self.assertRaisesRegex(ValueError, 'Circular package dependency'):
            packages.discover(self.repo, self.tracked, ['editor'], 'linux')

    def test_platform_choices_remain_package_owned(self) -> None:
        self.requirements('mux', "from system import Package\nPACKAGES = [Package('psmux', winget='marlocarlo.psmux')] if PLATFORM == 'windows' else [Package('tmux', ('tmux',))]\n")
        for platform, command in (('linux', 'tmux'), ('windows', 'psmux')):
            self.assertEqual(packages.discover(self.repo, self.tracked, ['mux'], platform).requirements[0].command, command)

    def test_requirement_alias_uses_the_shared_git_source(self) -> None:
        self.requirements('runtime', "from system import Package\nPACKAGES = [Package('node', ('nodejs',))]\n")
        self.requirements('editor', '../../runtime/.setup/requirements.py')
        self.tracked['editor/.setup/requirements.py'] = '120000'
        result = packages.discover(self.repo, self.tracked, ['editor'], 'linux')
        self.assertEqual(result.requirements, [system.Package('node', ('nodejs',))])

    def test_installed_tools_skip_install_but_clean_duplicates(self) -> None:
        package = system.Package('git', ('git',), 'Git.Git', scope='machine')
        with patch.object(system, 'installed', return_value=True), \
                patch.object(system, 'windows_cleanup') as cleanup, \
                patch.object(system.subprocess, 'run') as run:
            system.install([package, package])
            run.assert_not_called()
            if os.name == 'nt':
                cleanup.assert_called_once_with([package])

    def test_no_install_and_redirected_homes_cannot_change_machine(self) -> None:
        package = system.Package('missing', ('missing',), 'Fixture.Missing')
        for allow, redirected in ((False, '0'), (True, '1')):
            with patch.dict(os.environ, RC_SETUP_REDIRECTED=redirected), \
                    patch.object(system, 'installed', return_value=False), \
                    patch.object(system.subprocess, 'run') as run:
                with self.assertRaisesRegex(ValueError, 'Missing native requirements'):
                    system.install([package], allow=allow)
                run.assert_not_called()

    def test_machine_scope_leaves_user_packages_alone(self) -> None:
        machine = system.Package('machine', ('machine',), 'Fixture.Machine', scope='machine')
        user = system.Package('user', ('user',), 'Fixture.User', scope='user')
        with patch.object(system, 'installed', return_value=True) as installed, \
                patch.object(system, 'windows_cleanup'):
            system.install([user, machine], scope='machine')
        self.assertEqual([call.args[0] for call in installed.call_args_list], [machine])

    @unittest.skipUnless(os.name == 'nt', 'Windows account PATH')
    def test_redirected_tool_paths_never_touch_the_account_registry(self) -> None:
        with patch.dict(os.environ, RC_SETUP_REDIRECTED='1'), \
                patch.object(system.winreg, 'CreateKey') as registry:
            system.persist_path(self.repo)
            registry.assert_not_called()

    @unittest.skipUnless(sys.platform == 'linux', 'apt installation')
    def test_apt_groups_missing_requirements_and_checks_result(self) -> None:
        first = system.Package('one', ('shared', 'one'))
        second = system.Package('two', ('shared', 'two'))
        with patch.dict(os.environ, RC_SETUP_REDIRECTED='0'), \
                patch.object(system, 'installed', side_effect=[False, False, True, True]), \
                patch.object(system, 'apt') as apt:
            system.install([first, second, first])
        self.assertEqual(apt.call_args_list[1].args[0], ['install', '-y', 'shared', 'one', 'two'])

    @unittest.skipUnless(os.name == 'nt', 'WinGet installation')
    def test_user_command_does_not_satisfy_machine_requirement(self) -> None:
        package = system.Package('fixture', winget='Fixture.Tool')
        missing = subprocess.CompletedProcess([], 0x8a150014, '', '')
        with patch.dict(os.environ, RC_SETUP_REDIRECTED='0'), \
                patch.object(system, 'executable', return_value='user-tool.exe') as executable, \
                patch.object(system.subprocess, 'run', return_value=missing) as run:
            self.assertFalse(system.installed(package))
            command = run.call_args.args[0]
            self.assertEqual(command[command.index('--scope') + 1], 'machine')
            executable.assert_not_called()
            run.return_value = subprocess.CompletedProcess([], 0, '', '')
            self.assertTrue(system.installed(package))
            run.return_value = subprocess.CompletedProcess([], 5, '', 'access denied')
            with self.assertRaisesRegex(ValueError, 'WinGet inventory failed'):
                system.installed(package)

    @unittest.skipUnless(os.name == 'nt', 'WinGet installation')
    def test_machine_vim_requires_its_executable_on_the_machine_path(self) -> None:
        requirements = Path(__file__).resolve().parents[2] / 'vim/.setup/requirements.py'
        package = runpy.run_path(str(requirements), init_globals={'PLATFORM': 'windows'})['PACKAGES'][0]
        shared = self.repo / 'Program Files'
        vim = shared / 'Vim/vim.exe'
        vim.parent.mkdir(parents=True)
        vim.touch()
        with patch.dict(os.environ, ProgramFiles=str(shared)), \
                patch.object(system.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0)), \
                patch.object(system.winreg, 'OpenKey'), \
                patch.object(system.winreg, 'QueryValueEx', return_value=('', 1)) as path:
            self.assertFalse(system.windows_registered(package))
            path.return_value = (str(vim.parent), 1)
            self.assertTrue(system.windows_registered(package))
            vim.unlink()
            self.assertFalse(system.windows_registered(package))

    @unittest.skipUnless(os.name == 'nt', 'WinGet installation')
    def test_provisioned_apps_can_come_from_either_machine_inventory(self) -> None:
        package = system.Package('wt', winget='Microsoft.WindowsTerminal',
                                 provisioned='Microsoft.WindowsTerminal')
        root = r'SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore'
        inventories = {'InboxApplications': [], 'Applications': []}

        def open_key(hive: int, key: str) -> MagicMock:
            self.assertEqual(hive, system.winreg.HKEY_LOCAL_MACHINE)
            name = key.removeprefix(root + '\\')
            if name not in inventories:
                raise FileNotFoundError(key)
            handle = MagicMock()
            handle.__enter__.return_value = inventories[name]
            return handle

        with patch.object(system.winreg, 'OpenKey', side_effect=open_key), \
                patch.object(system.winreg, 'QueryInfoKey', side_effect=lambda names: (len(names), 0, 0)), \
                patch.object(system.winreg, 'EnumKey', side_effect=lambda names, index: names[index]):
            self.assertFalse(system.windows_registered(package))
            for inventory in inventories:
                inventories[inventory] = ['Microsoft.WindowsTerminal_3001.24.12741.0_neutral_~_8wekyb3d8bbwe']
                self.assertTrue(system.windows_registered(package))
                inventories[inventory] = ['Microsoft.WindowsTerminalPreview_1.0_x64__8wekyb3d8bbwe']
                self.assertFalse(system.windows_registered(package))
            del inventories['InboxApplications']
            inventories['Applications'] = ['Microsoft.WindowsTerminal_1.0_x64__8wekyb3d8bbwe']
            self.assertTrue(system.windows_registered(package))

    @unittest.skipUnless(os.name == 'nt', 'WinGet installation')
    def test_no_install_does_not_refresh_shared_npm_packages(self) -> None:
        package = system.Package('fixture', npm='@fixture/cli')
        with patch.dict(os.environ, RC_SETUP_UPDATE='1'), \
                patch.object(system, 'installed', return_value=True), \
                patch.object(system, 'windows_cleanup') as cleanup, \
                patch.object(system, 'windows_install') as install:
            system.install([package], allow=False)
            install.assert_not_called()
            cleanup.assert_not_called()
            system.install([package])
            install.assert_called_once_with([package])

    @unittest.skipUnless(os.name == 'nt', 'WinGet installation')
    def test_windows_groups_packages_once_and_checks_result(self) -> None:
        package = system.Package('one', winget='Fixture.One', scope='machine')
        with patch.dict(os.environ, RC_SETUP_REDIRECTED='0'), \
                patch.object(system, 'installed', side_effect=[False, False]), \
                patch.object(system, 'windows_install') as install, \
                patch.object(system, 'windows_cleanup') as cleanup:
            with self.assertRaisesRegex(ValueError, 'still missing after installation'):
                system.install([package, package])
        install.assert_called_once_with([package])
        cleanup.assert_not_called()

    @unittest.skipUnless(os.name == 'nt', 'WinGet installation')
    def test_redirected_home_does_not_remove_duplicates(self) -> None:
        with patch.dict(os.environ, RC_SETUP_REDIRECTED='1'), \
                patch.object(system, 'installed', return_value=True), \
                patch.object(system, 'windows_cleanup') as cleanup:
            system.install([system.Package('fixture', winget='Fixture.Tool')])
        cleanup.assert_not_called()

    @unittest.skipUnless(os.name == 'nt', 'WinGet installation')
    def test_cleanup_excludes_user_requirements_and_shared_app_registrations(self) -> None:
        ordinary = system.Package('fixture', winget='Fixture.Tool')
        user = system.Package('user', winget='Fixture.User', scope='user')
        terminal = system.Package('wt', winget='Microsoft.WindowsTerminal', provisioned='Microsoft.WindowsTerminal')
        with patch.object(system, 'windows_install') as install, \
                patch.object(system, 'installed', return_value=True):
            system.windows_cleanup([ordinary, user, terminal])
        install.assert_called_once_with([ordinary], cleanup_only=True)


if __name__ == '__main__':
    unittest.main()
