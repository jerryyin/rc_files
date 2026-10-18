import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from context import Context
import vim

entry = Path(__file__).resolve().parents[1] / '__main__.py'
spec = importlib.util.spec_from_file_location('rc_setup', entry)
setup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(setup)


class ApplicationTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix='rc-apps-')
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name).resolve()
        self.repo = self.root / 'checkout'
        self.home = self.root / "Someone's home"
        self.repo.mkdir()
        self.home.mkdir()
        self.context = Context(self.repo, self.home, 'linux')

    def test_vim_uses_the_same_driver_on_both_platforms(self) -> None:
        for platform in ('linux', 'windows'):
            with self.subTest(platform=platform), patch.object(vim, 'extensions') as extensions, \
                    patch.object(Context, 'run') as run:
                context = Context(self.repo, self.home, platform)
                vim.setup(context, vim_exe=Path('native-vim'))
                command = run.call_args.args[0]
                self.assertEqual(command[0], 'native-vim')
                self.assertEqual(Path(command[-1]).name, 'vim-plugins.vim')
                extensions.assert_called_once_with(context)

    def test_vim_discovery_uses_path_instead_of_installation_locations(self) -> None:
        native = self.root / 'bin/vim'
        with patch.object(vim.shutil, 'which', return_value=str(native)):
            self.assertEqual(vim.executable(), native)
        with patch.object(vim.shutil, 'which', return_value=None):
            self.assertIsNone(vim.executable())

    def test_vim_failure_stops_before_npm(self) -> None:
        with patch.object(vim, 'extensions') as extensions, \
                patch.object(Context, 'run', side_effect=subprocess.CalledProcessError(23, ['vim'])):
            with self.assertRaises(subprocess.CalledProcessError) as failure:
                vim.setup(self.context, vim_exe=Path('vim'))
            self.assertEqual(failure.exception.returncode, 23)
            extensions.assert_not_called()

    def test_npm_owns_runtime_package_data_and_checks_all_choices_at_latest(self) -> None:
        choices = self.repo / 'vim/.vim/coc-extensions.json'
        choices.parent.mkdir(parents=True)
        choices.write_text('["coc-json"]')
        package = self.home / '.config/coc/extensions/package.json'
        package.parent.mkdir(parents=True)
        package.write_text(json.dumps({'private': True, 'dependencies': {'coc-personal': '^1.0.0'}}))
        before = package.read_bytes()
        with patch.object(vim.shutil, 'which', return_value='npm'), patch.object(Context, 'run') as run:
            vim.extensions(self.context)
            self.assertEqual(run.call_args.args[0], [
                'npm', 'install', '--save', '--no-package-lock', 'coc-json@latest', 'coc-personal@latest',
            ])
            self.assertEqual(run.call_args.kwargs['cwd'], package.parent)
            self.assertEqual(package.read_bytes(), before)
        with patch.object(vim.shutil, 'which', return_value='npm'), \
                patch.object(Context, 'run', side_effect=subprocess.CalledProcessError(1, ['npm'])):
            with self.assertRaises(subprocess.CalledProcessError):
                vim.extensions(self.context)

    def test_setup_in_another_home_never_changes_account_settings(self) -> None:
        with patch.object(setup.links, 'run', return_value=0), \
                patch.object(setup.mux, 'setup'), patch.object(setup.vim, 'setup'), \
                patch.object(Context, 'run') as run:
            self.assertEqual(setup.main(['--repo', str(self.repo), '--home', str(self.home)]), 0)
            if sys.platform == 'linux':
                self.assertEqual(run.call_args.args[0], ['zsh', '-c', 'source "$HOME/.zshrc"'])
            else:
                run.assert_not_called()

    def test_setup_stops_at_application_failure(self) -> None:
        with patch.object(setup.links, 'run', return_value=0) as links, \
                patch.object(setup.mux, 'setup', side_effect=ValueError('plugin failure')), \
                patch.object(setup.vim, 'setup') as vim_setup:
            with self.assertRaisesRegex(ValueError, 'plugin failure'):
                setup.main(['--repo', str(self.repo), '--home', str(self.home)])
            self.assertEqual(links.call_args.args[0].action, 'migrate')
            vim_setup.assert_not_called()

    def test_configuration_only_does_not_run_installers(self) -> None:
        with patch.object(setup.links, 'run', return_value=0), \
                patch.object(setup.mux, 'setup') as mux_setup, \
                patch.object(setup.vim, 'setup') as vim_setup, patch.object(Context, 'run') as run:
            self.assertEqual(setup.main(['--repo', str(self.repo), '--home', str(self.home), '--config-only']), 0)
            mux_setup.assert_not_called()
            vim_setup.assert_not_called()
            run.assert_not_called()

    def test_setup_environment_is_explicit_and_keeps_public_clones_noninteractive(self) -> None:
        environment = self.context.environment()
        self.assertEqual(environment['HOME'], str(self.home))
        self.assertEqual(environment['RC_SETUP'], '1')
        self.assertEqual(environment['RC_SETUP_UPDATE'], '0')
        self.assertEqual(environment['GIT_TERMINAL_PROMPT'], '0')
