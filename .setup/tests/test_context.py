import os
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from context import environment


class EnvironmentTests(unittest.TestCase):
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
