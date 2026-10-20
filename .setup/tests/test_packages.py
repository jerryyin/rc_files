import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

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

    def test_installed_tools_never_call_package_manager(self) -> None:
        package = system.Package('git', ('git',), 'Git.Git', scope='machine')
        with patch.object(system, 'installed', return_value=True), patch.object(system.subprocess, 'run') as run:
            system.install([package, package])
            run.assert_not_called()

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
        user = system.Package('user', ('user',), 'Fixture.User')
        with patch.object(system, 'installed', return_value=True) as installed:
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
    def test_windows_groups_packages_once_and_checks_result(self) -> None:
        package = system.Package('one', winget='Fixture.One', scope='machine')
        with patch.dict(os.environ, RC_SETUP_REDIRECTED='0'), \
                patch.object(system, 'installed', side_effect=[False, False]), \
                patch.object(system, 'windows_install') as install:
            with self.assertRaisesRegex(ValueError, 'still missing after installation'):
                system.install([package, package])
        install.assert_called_once_with([package])


if __name__ == '__main__':
    unittest.main()
