import importlib.util
import io
import json
import os
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / '.setup'))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
spec = importlib.util.spec_from_file_location('node_setup', Path(__file__).resolve().parents[1] / '__main__.py')
node = importlib.util.module_from_spec(spec)
spec.loader.exec_module(node)


class NodeTests(unittest.TestCase):
    def test_supported_node_and_npm_skip_installation(self) -> None:
        with patch.object(node, 'version', return_value=(22, 19, 0)), \
                patch.object(node.shutil, 'which', return_value='npm'), \
                patch.object(node, 'apt') as apt, patch.object(node.urllib.request, 'urlopen') as download:
            node.setup()
            apt.assert_not_called()
            download.assert_not_called()

    def test_missing_node_in_no_install_or_redirected_home_fails_without_downloads(self) -> None:
        for install, redirected in (('0', '0'), ('1', '1')):
            with patch.dict(os.environ, RC_SETUP_INSTALL=install, RC_SETUP_REDIRECTED=redirected), \
                    patch.object(node, 'version', return_value=()), \
                    patch.object(node.urllib.request, 'urlopen') as download:
                with self.assertRaisesRegex(ValueError, 'install them in the real account'):
                    node.setup()
                download.assert_not_called()

    @unittest.skipUnless(sys.platform == 'linux', 'Linux NodeSource repository')
    def test_missing_node_selects_latest_lts_and_verifies_installed_result(self) -> None:
        releases = [{'version': 'v99.0.0', 'lts': False}, {'version': 'v24.9.0', 'lts': 'Krypton'},
                    {'version': 'v22.19.0', 'lts': 'Jod'}]
        sources: list[str] = []

        def run(command: list[str], **kwargs: object) -> None:
            if command[0] == 'install':
                sources.append(Path(command[-2]).read_text())

        with patch.dict(os.environ, RC_SETUP_INSTALL='1', RC_SETUP_REDIRECTED='0'), \
                patch.object(node, 'version', side_effect=[(), (24, 9, 0)]), \
                patch.object(node.shutil, 'which', return_value='npm'), \
                patch.object(node, 'privileged', return_value=[]), patch.object(node, 'apt') as apt, \
                patch.object(node.urllib.request, 'urlopen', return_value=io.BytesIO(json.dumps(releases).encode())), \
                patch.object(node.urllib.request, 'urlretrieve'), \
                patch.object(node.subprocess, 'check_output', return_value='amd64\n'), \
                patch.object(node.subprocess, 'run', side_effect=run):
            node.setup()
        self.assertEqual(apt.call_args_list[-1].args[0], ['install', '-y', 'nodejs'])
        self.assertIn('https://deb.nodesource.com/node_24.x', sources[0])
        self.assertIn('Signed-By: /usr/share/keyrings/nodesource.gpg', sources[0])


if __name__ == '__main__':
    unittest.main()
