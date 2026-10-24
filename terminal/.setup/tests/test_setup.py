import os
from pathlib import Path
import runpy
import unittest
from unittest.mock import patch


ENTRY = Path(__file__).resolve().parents[1] / '__main__.py'


@unittest.skipUnless(os.name == 'nt', 'Windows font setup')
class TerminalSetupTests(unittest.TestCase):
    def test_font_helper_uses_process_only_execution_policy(self) -> None:
        with patch.dict(os.environ, RC_SETUP_REDIRECTED='0', RC_SETUP_INSTALL='1'), \
                patch('subprocess.run') as run:
            runpy.run_path(str(ENTRY), run_name='__main__')
        self.assertEqual(run.call_args.args[0][:5],
                         ['powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File'])
        self.assertTrue(run.call_args.kwargs['check'])

    def test_redirected_and_no_install_setup_do_not_touch_fonts(self) -> None:
        for redirected, install in (('1', '1'), ('0', '0')):
            with self.subTest(redirected=redirected, install=install), \
                    patch.dict(os.environ, RC_SETUP_REDIRECTED=redirected, RC_SETUP_INSTALL=install), \
                    patch('subprocess.run') as run:
                runpy.run_path(str(ENTRY), run_name='__main__')
                run.assert_not_called()
