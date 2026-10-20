import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


sys.path.insert(0, str(Path(__file__).resolve().parents[3] / '.setup'))
entry = Path(__file__).resolve().parents[1] / '__main__.py'
spec = importlib.util.spec_from_file_location('vim_setup', entry)
vim = importlib.util.module_from_spec(spec)
spec.loader.exec_module(vim)


class VimSetupTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix='rc-vim-')
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name).resolve()
        self.package = self.root / "Someone's Vim package"
        self.home = self.root / "Someone's home"
        self.home.mkdir()
        choices = self.package / '.vim/coc-extensions.json'
        choices.parent.mkdir(parents=True)
        choices.write_text('["coc-json", "coc-json"]')
        setup_entry = self.package / '.setup/__main__.py'
        setup_entry.parent.mkdir()
        self.file_patch = patch.object(vim, '__file__', str(setup_entry))
        self.file_patch.start()
        persistence = patch.object(vim, 'persist_path')
        persistence.start()
        self.addCleanup(persistence.stop)
        self.addCleanup(self.file_patch.stop)

    def test_vim_uses_its_own_driver_and_native_executable(self) -> None:
        native = self.root / 'bin/vim'
        with patch.object(vim, 'executable', return_value=native), \
                patch.object(vim, 'extensions') as extensions, patch.object(vim.subprocess, 'run') as run:
            vim.setup(self.home)
        command = run.call_args_list[0].args[0]
        self.assertEqual(command[0], str(native))
        self.assertEqual(Path(command[-1]), self.package / '.setup/vim-plugins.vim')
        self.assertIn('-u', command)
        self.assertTrue(run.call_args_list[0].kwargs['check'])
        extensions.assert_called_once_with(self.home)

    def test_vim_discovery_uses_path(self) -> None:
        native = self.root / 'bin/vim'
        with patch.object(vim.shutil, 'which', return_value=str(native)):
            self.assertEqual(vim.executable(), native)
        with patch.object(vim.shutil, 'which', return_value=None):
            self.assertIsNone(vim.executable())

    @unittest.skipUnless(os.name == 'nt', 'Windows executable discovery')
    def test_git_for_windows_vim_is_rejected(self) -> None:
        with patch.object(vim.shutil, 'which', return_value='C:/Program Files/Git/usr/bin/vim.exe'):
            self.assertIsNone(vim.executable())

    def test_missing_vim_does_not_run_installers(self) -> None:
        with patch.object(vim, 'executable', return_value=None), patch.object(vim.subprocess, 'run') as run:
            with self.assertRaisesRegex(ValueError, 'Native Vim is not on PATH'):
                vim.setup(self.home)
            run.assert_not_called()

    def test_vim_failure_stops_before_npm(self) -> None:
        with patch.object(vim, 'executable', return_value=Path('vim')), \
                patch.object(vim, 'extensions') as extensions, \
                patch.object(vim.subprocess, 'run', side_effect=subprocess.CalledProcessError(23, ['vim'])):
            with self.assertRaises(subprocess.CalledProcessError) as failure:
                vim.setup(self.home)
            self.assertEqual(failure.exception.returncode, 23)
            extensions.assert_not_called()

    @unittest.skipUnless(vim.executable(), 'Native Vim is required for the driver check')
    def test_headless_install_and_update_are_sequential_and_reject_incomplete_checkouts(self) -> None:
        driver = self.package / '.setup/vim-plugins.vim'
        shutil.copy2(entry.with_name('vim-plugins.vim'), driver)
        config = self.package / '.vim/config/plugins.vim'
        config.parent.mkdir(exist_ok=True)
        config.write_text('''
let g:plugs = {'fixture': {'dir': expand('~/.vim/plugged/fixture')}}
function! InstallFixture(action)
  if g:plug_threads != 1
    throw 'Headless setup must use one job'
  endif
  call writefile([a:action], expand('~/action'))
  if $FIXTURE_COMPLETE ==# '1'
    call mkdir(g:plugs.fixture.dir . '/.git', 'p')
    call writefile(['ref: refs/heads/main'], g:plugs.fixture.dir . '/.git/HEAD')
  endif
endfunction
command! -nargs=* PlugInstall call InstallFixture('install')
command! -nargs=* PlugUpdate call InstallFixture('update')
''')
        for update, complete in ((False, True), (True, True), (False, False)):
            with self.subTest(update=update, complete=complete):
                shutil.rmtree(self.home / '.vim', ignore_errors=True)
                result = subprocess.run([
                    str(vim.executable()), '-n', '-i', 'NONE', '-E', '-s', '-u', 'NONE', '-S', str(driver)],
                    env=dict(os.environ, HOME=str(self.home), USERPROFILE=str(self.home),
                             RC_SETUP_UPDATE=str(int(update)), FIXTURE_COMPLETE=str(int(complete))),
                    text=True, capture_output=True, timeout=30)
                self.assertEqual(result.returncode, 0 if complete else 1, result.stdout + result.stderr)
                self.assertEqual((self.home / 'action').read_text().strip(), 'update' if update else 'install')

    def test_npm_preserves_runtime_metadata_and_installs_all_choices_at_latest(self) -> None:
        package = self.home / '.config/coc/extensions/package.json'
        package.parent.mkdir(parents=True)
        package.write_text(json.dumps({'private': True, 'dependencies': {'coc-personal': '^1.0.0'}}))
        before = package.read_bytes()
        with patch.object(vim.shutil, 'which', return_value='npm'), patch.object(vim.subprocess, 'run') as run:
            vim.extensions(self.home)
        self.assertEqual(run.call_args.args[0], [
            'npm', 'install', '--save', '--no-package-lock', 'coc-json@latest', 'coc-personal@latest',
        ])
        self.assertEqual(run.call_args.kwargs['cwd'], package.parent)
        self.assertTrue(run.call_args_list[0].kwargs['check'])
        self.assertEqual(package.read_bytes(), before)

    def test_npm_creates_a_fresh_runtime_directory(self) -> None:
        with patch.object(vim.shutil, 'which', return_value='npm'), patch.object(vim.subprocess, 'run') as run:
            vim.extensions(self.home)
        self.assertTrue((self.home / '.config/coc/extensions').is_dir())
        self.assertEqual(run.call_args.args[0][-1], 'coc-json@latest')

    def test_npm_uses_system_certificates_without_overriding_an_explicit_bundle(self) -> None:
        for existing in ('', '/user/certificates.pem'):
            with self.subTest(existing=existing), patch.dict(os.environ, NODE_EXTRA_CA_CERTS=existing), \
                    patch.object(vim.ssl, 'get_default_verify_paths') as paths, \
                    patch.object(vim.shutil, 'which', return_value='npm'), \
                    patch.object(vim.subprocess, 'run') as run:
                paths.return_value.cafile = '/system/certificates.pem'
                vim.extensions(self.home)
                self.assertEqual(run.call_args.kwargs['env']['NODE_EXTRA_CA_CERTS'],
                                 existing or '/system/certificates.pem')

    def test_missing_npm_and_failed_install_are_errors(self) -> None:
        with patch.object(vim.shutil, 'which', return_value=None):
            with self.assertRaisesRegex(ValueError, 'npm is required'):
                vim.extensions(self.home)
        with patch.object(vim.shutil, 'which', return_value='npm'), \
                patch.object(vim.subprocess, 'run', side_effect=subprocess.CalledProcessError(1, ['npm'])):
            with self.assertRaises(subprocess.CalledProcessError):
                vim.extensions(self.home)


if __name__ == '__main__':
    unittest.main()
