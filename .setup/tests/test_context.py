import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from context import environment, prepare


class EnvironmentTests(unittest.TestCase):
    @unittest.skipUnless(os.name == 'nt', 'Windows application data')
    def test_redirected_application_directories_exist_before_launch(self) -> None:
        with tempfile.TemporaryDirectory(prefix='rc-appdata-') as temporary:
            settings = environment(Path(temporary).resolve(), False)
            self.assertFalse(Path(settings['LOCALAPPDATA']).exists())
            prepare(settings)
            self.assertTrue(Path(settings['APPDATA']).is_dir())
            self.assertTrue(Path(settings['LOCALAPPDATA']).is_dir())

    def test_environment_home_override_is_still_a_redirected_account(self) -> None:
        with tempfile.TemporaryDirectory(prefix='rc-redirected-') as temporary:
            home = Path(temporary).resolve()
            with patch.dict(os.environ, HOME=str(home), USERPROFILE=str(home)):
                result = environment(home, False)
            self.assertEqual(result['RC_SETUP_REDIRECTED'], '1')
            self.assertEqual(Path(result['XDG_CONFIG_HOME']), home / '.config')
            if os.name == 'nt':
                self.assertEqual(Path(result['LOCALAPPDATA']), home / 'AppData/Local')

    def test_native_home_preserves_account_directory_overrides(self) -> None:
        home = Path.home().resolve()
        overrides = {'XDG_CONFIG_HOME': 'custom-config', 'XDG_CACHE_HOME': 'custom-cache',
                     'XDG_DATA_HOME': 'custom-data', 'APPDATA': 'custom-roaming',
                     'LOCALAPPDATA': 'custom-local', 'RC_SETUP_REDIRECTED': '1'}
        with patch.dict(os.environ, overrides):
            result = environment(home, False)
        self.assertEqual(result['RC_SETUP_REDIRECTED'], '0')
        for name, value in overrides.items():
            if name != 'RC_SETUP_REDIRECTED':
                self.assertEqual(result[name], value)

    def test_package_environment_does_not_add_node_configuration(self) -> None:
        home = Path.home().resolve()
        with patch.dict(os.environ):
            os.environ.pop('NODE_EXTRA_CA_CERTS', None)
            self.assertNotIn('NODE_EXTRA_CA_CERTS', environment(home, False))


if __name__ == '__main__':
    unittest.main()
