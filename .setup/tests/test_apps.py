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
import mux
import shell
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
        self.context = Context(self.repo, self.home, self.root / 'backup', 'linux')

    def write(self, root: Path, name: str, value: str) -> Path:
        path = root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(value, encoding='utf-8')
        return path

    def test_vim_uses_the_same_driver_on_both_platforms(self) -> None:
        self.write(self.repo, 'vim/.vim/coc-extensions.json', '["coc-json"]')
        self.write(self.home, '.vim/autoload/plug.vim', 'already installed')
        for platform in ('linux', 'windows'):
            with self.subTest(platform=platform), patch.object(vim, 'configure'), \
                    patch.object(vim, 'extensions') as extensions, patch.object(Context, 'run') as run:
                context = Context(self.repo, self.home, self.root / 'backup', platform)
                vim.setup(context, vim_exe=Path('native-vim'))
                command = run.call_args.args[0]
                self.assertEqual(command[0], 'native-vim')
                self.assertEqual(Path(command[-1]).name, 'vim-plugins.vim')
                self.assertEqual(run.call_args.kwargs['environment']['RC_SETUP_REPO'], str(self.repo))
                extensions.assert_called_once_with(context)

    def test_vim_failure_stops_before_npm(self) -> None:
        self.write(self.home, '.vim/autoload/plug.vim', 'already installed')
        with patch.object(vim, 'configure'), patch.object(vim, 'extensions') as extensions, \
                patch.object(Context, 'run', side_effect=subprocess.CalledProcessError(23, ['vim'])):
            with self.assertRaises(subprocess.CalledProcessError) as failure:
                vim.setup(self.context, vim_exe=Path('vim'))
            self.assertEqual(failure.exception.returncode, 23)
            extensions.assert_not_called()

    def test_extensions_retain_choices_and_always_check_latest(self) -> None:
        self.write(self.repo, 'vim/.vim/coc-extensions.json', '["coc-json"]')
        package = self.write(self.home, '.config/coc/extensions/package.json', json.dumps({
            'private': True, 'dependencies': {'coc-personal': '^1.0.0'},
        }))
        with patch.object(vim.shutil, 'which', return_value='npm'), patch.object(Context, 'run') as run:
            vim.extensions(self.context)
            self.assertEqual(json.loads(package.read_text()), {
                'private': True, 'dependencies': {'coc-personal': 'latest', 'coc-json': 'latest'},
            })
            self.assertEqual(run.call_args.args[0], ['npm', 'install', '--no-save', '--no-package-lock'])
            self.assertEqual(run.call_args.kwargs['cwd'], package.parent)
            for name in ('coc-json', 'coc-personal'):
                self.write(package.parent, f'node_modules/{name}/package.json', '{}')
            before = package.stat().st_mtime_ns
            vim.extensions(self.context)
            self.assertEqual(run.call_args.args[0][1], 'update')
            self.assertEqual(package.stat().st_mtime_ns, before)

    def test_bash_fallback_is_repeatable_and_points_to_tracked_runtime(self) -> None:
        path = self.write(self.home, '.bashrc', '# personal content\n')
        shell.bash_fallback(self.context)
        before = path.stat().st_mtime_ns
        shell.bash_fallback(self.context)
        self.assertEqual(path.stat().st_mtime_ns, before)
        self.assertTrue(path.read_text().startswith('# personal content\n'))
        self.assertEqual(path.read_text().count('auto-exec zsh (chsh unavailable) >>>'), 1)
        self.assertIn('$HOME/.config/zsh/interactive.sh', path.read_text())

    def test_setup_calls_modules_directly_and_stops_at_failure(self) -> None:
        with patch.object(setup.links, 'run', return_value=0) as links, \
                patch.object(setup.mux, 'setup', side_effect=ValueError('plugin failure')) as mux_setup, \
                patch.object(setup.vim, 'setup') as vim_setup, patch.object(Path, 'home', return_value=self.home):
            with self.assertRaisesRegex(ValueError, 'plugin failure'):
                setup.main(['--repo', str(self.repo)])
            self.assertEqual(links.call_args.args[0].action, 'migrate')
            mux_setup.assert_called_once()
            vim_setup.assert_not_called()

    def test_configuration_only_does_not_call_application_modules(self) -> None:
        with patch.object(setup.links, 'run', return_value=0) as links, \
                patch.object(setup.mux, 'setup') as mux_setup, \
                patch.object(setup.vim, 'setup') as vim_setup, patch.object(setup.shell, 'setup') as shell_setup:
            self.assertEqual(setup.main(['--repo', str(self.repo), '--home', str(self.home), '--config-only']), 0)
            self.assertEqual(links.call_args.args[0].action, 'migrate')
            mux_setup.assert_not_called()
            vim_setup.assert_not_called()
            shell_setup.assert_not_called()


class MuxTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix='rc-mux-')
        self.addCleanup(temporary.cleanup)
        self.repo = Path(temporary.name).resolve()
        (self.repo / 'tmux/.windows/.tmux').mkdir(parents=True)
        checkout = Path(__file__).resolve().parents[2]
        compatibility = checkout / 'tmux/.windows/.tmux/psmux-compat.conf'
        (self.repo / 'tmux/.windows/.tmux/psmux-compat.conf').write_bytes(compatibility.read_bytes())

    def test_renderer_preserves_shared_preferences_and_declared_plugin_keys(self) -> None:
        source = self.repo / 'tmux/.tmux.conf'
        source.write_text('''set -g prefix C-a
set-option -g status-style bg=default
set -g status-right "#[fg=colour223,bg=colour239] $wg_is_keys_off %Y-%m-%d"
set-option -g default-command "zsh -l"
set -g @pane_resize '8'
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-pain-control'
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @plugin 'tmux-plugins/tmux-resurrect'
''')
        result = mux.render(self.repo, self.repo)
        for text in ('set -g prefix C-a', 'set-option -g status-style bg=default',
                     '#[fg=colour223,bg=colour239]', 'bind-key -r Left select-pane -L',
                     'bind-key h select-pane -L', 'bind-key C-l select-pane -R',
                     'bind-key -r H resize-pane -L 8', 'bind-key -r ">" swap-window -d -t +1'):
            self.assertIn(text, result)
        for key in ('I', 'U', 'M-u', 'C-s', 'C-r', 'y', 'Y'):
            self.assertIn('bind-key ' + key + ' ', result)
        self.assertNotIn('zsh -l', result)
        self.assertNotIn('$wg_is_keys_off', result)
        source.write_text('set -g prefix C-a\n')
        plain = mux.render(self.repo, self.repo)
        self.assertNotIn('bind-key h ', plain)
        self.assertNotIn('psmux-resurrect', plain)
