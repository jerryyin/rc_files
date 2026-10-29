import importlib.util
import os
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / '.setup'))
spec = importlib.util.spec_from_file_location('gh_setup', Path(__file__).resolve().parents[1] / '__main__.py')
gh = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gh)


@unittest.skipUnless(sys.platform == 'linux', 'GitHub Linux package feed')
class GitHubTests(unittest.TestCase):
    def test_launcher_alone_does_not_count_as_an_installed_native_cli(self) -> None:
        launcher = Path(gh.__file__).resolve().parents[1] / '.linux/.local/bin/gh'
        with patch.dict(os.environ, RC_SETUP_INSTALL='1', RC_SETUP_REDIRECTED='1'), \
                patch.object(gh.shutil, 'which', side_effect=[str(launcher), None]), patch.object(gh, 'apt') as apt:
            with self.assertRaisesRegex(ValueError, 'install it in the real account'):
                gh.setup()
            apt.assert_not_called()

    def test_installed_cli_is_reused_without_network_or_installation(self) -> None:
        with patch.object(gh.shutil, 'which', return_value='gh'), patch.object(gh, 'apt') as apt:
            gh.setup()
            apt.assert_not_called()

    def test_redirected_home_cannot_install_a_missing_cli(self) -> None:
        with patch.dict(os.environ, RC_SETUP_INSTALL='1', RC_SETUP_REDIRECTED='1'), \
                patch.object(gh.shutil, 'which', return_value=None), patch.object(gh, 'apt') as apt:
            with self.assertRaisesRegex(ValueError, 'install it in the real account'):
                gh.setup()
            apt.assert_not_called()

    def test_missing_cli_uses_publisher_feed_and_checks_the_result(self) -> None:
        sources: list[str] = []

        def run(command: list[str], **kwargs: object) -> None:
            if command[-1].endswith('/github-cli.list'):
                sources.append(Path(command[-2]).read_text())

        with patch.dict(os.environ, RC_SETUP_INSTALL='1', RC_SETUP_REDIRECTED='0'), \
                patch.object(gh.shutil, 'which', side_effect=[None, 'gh']), \
                patch.object(gh, 'privileged', return_value=[]), patch.object(gh, 'apt') as apt, \
                patch.object(gh.urllib.request, 'urlretrieve'), \
                patch.object(gh.subprocess, 'check_output', return_value='amd64\n'), \
                patch.object(gh.subprocess, 'run', side_effect=run):
            gh.setup()
        self.assertIn('https://cli.github.com/packages stable main', sources[0])
        self.assertEqual(apt.call_args_list[-1].args[0], ['install', '-y', 'gh'])
