import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile
import unittest


@unittest.skipIf(os.name == 'nt', 'Windows console Vim is checked by Test-VimShortcuts.ps1')
class ReviewTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix='vim-review-')
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name).resolve()
        self.project = self.root / 'project with spaces'
        self.project.mkdir()
        self.package = Path(__file__).resolve().parents[2]
        self.fugitive = Path.home() / '.vim/plugged/vim-fugitive'
        if not (self.fugitive / 'plugin/fugitive.vim').is_file():
            self.skipTest('Installed Fugitive is required')
        self.environment = dict(os.environ, GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM='1')
        self.git('init', '-q')
        for version in ('original', 'committed'):
            self.write(version)
            self.git('add', 'review.py')
            self.git('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
                     '-c', 'core.hooksPath=' + os.devnull, 'commit', '-qm', version)
        self.write('staged')
        self.git('add', 'review.py')
        self.write('working')

    def git(self, *arguments: str) -> None:
        subprocess.run(['git', '-C', str(self.project), *arguments],
                       env=self.environment, check=True, capture_output=True)

    def write(self, version: str) -> None:
        (self.project / 'review.py').write_text('value = "' + version + ' ' * 180 + '"\n')

    def command(self, editor: str, log: Path) -> list[str]:
        executable = shutil.which(editor)
        if not executable:
            self.skipTest(editor + ' is required')
        probe = Path(__file__).with_name('review.vim')
        if editor == 'nvim':
            command = [executable, '--headless', '-u', 'NONE', '-c', 'lua dofile(vim.env.RC_REVIEW_OPTIONS)']
        else:
            command = [executable, '-u', str(self.package / '.vimrc')]
        command += ['-n', '-i', 'NONE', '-V1' + str(log), '-S', str(probe), '-c', 'qa!']
        if editor == 'vim':
            terminal = shutil.which('script')
            if not terminal:
                self.skipTest('script is required for terminal Vim')
            command = [terminal, '-q', '-e', '-c', shlex.join(command), os.devnull]
        return command

    def review(self, editor: str) -> None:
        report = self.root / (editor + '.json')
        log = self.root / (editor + '.log')
        environment = dict(self.environment, RC_REVIEW_FUGITIVE=str(self.fugitive),
                           RC_REVIEW_REPORT=str(report), RC_REVIEW_PROJECT=str(self.project),
                           RC_REVIEW_OPTIONS=str(self.package / '.linux/.config/nvim/lua/config/options.lua'))
        result = subprocess.run(self.command(editor, log), cwd=self.project,
                                env=environment, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr + log.read_text(errors='replace'))
        results = json.loads(report.read_text())
        self.assertEqual(results['error'], '')
        self.assertEqual(len(results['cases']), 4)
        for case in results['cases']:
            with self.subTest(editor=editor, case=case['case']):
                self.assertEqual(len(case['windows']), 2, case)
                self.assertEqual([window['wrap'] for window in case['windows']], [1, 1], case)
                self.assertTrue(any(window['fugitive'] for window in case['windows']), case)
                self.assertEqual(case['after'], 1, case)

    def test_vim_wraps_both_sides_of_fugitive_reviews(self) -> None:
        self.review('vim')

    def test_neovim_wraps_both_sides_of_fugitive_reviews(self) -> None:
        self.review('nvim')


if __name__ == '__main__':
    unittest.main()
