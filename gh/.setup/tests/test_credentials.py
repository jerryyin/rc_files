import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / '.setup'))
spec = importlib.util.spec_from_file_location('gh_credentials', Path(__file__).resolve().parents[1] / 'credentials.py')
credentials = importlib.util.module_from_spec(spec)
spec.loader.exec_module(credentials)

TOKENS = {'jerryyin': 'fixture-personal', 'zhuoryin_amdeng': 'fixture-enterprise'}


class WindowsCredentialTests(unittest.TestCase):
    def run_hook(self, logins: list[str], update: str = '0') -> list[tuple[list[str], str]]:
        calls: list[tuple[list[str], str]] = []
        hosts = {'hosts': {'github.com': [{'login': login, 'state': 'success'} for login in logins]}}

        def fake(arguments: list[str], text: str) -> subprocess.CompletedProcess[str]:
            calls.append((arguments[1:], text))
            output = json.dumps(hosts) if arguments[1:3] == ['auth', 'status'] else ''
            return subprocess.CompletedProcess(arguments, 0, output, '')

        with patch.dict(os.environ, RC_SETUP_UPDATE=update), \
                patch.object(credentials.shutil, 'which', return_value='gh'), \
                patch.object(credentials, 'command', side_effect=fake):
            credentials.windows(TOKENS)
        return calls

    def test_new_machine_signs_in_both_vault_accounts_without_a_browser(self) -> None:
        calls = self.run_hook([])
        logins = [text for arguments, text in calls if arguments[:2] == ['auth', 'login']]
        self.assertEqual(logins, list(TOKENS.values()))
        self.assertTrue(all('--with-token' in arguments and '--web' not in arguments
                            for arguments, _ in calls if arguments[:2] == ['auth', 'login']))
        self.assertIn(['auth', 'switch', '--hostname', 'github.com', '--user', 'zhuoryin_amdeng'],
                      [arguments for arguments, _ in calls])

    def test_existing_accounts_and_active_choice_are_preserved(self) -> None:
        calls = self.run_hook(['jerryyin'])
        self.assertEqual([text for arguments, text in calls if arguments[:2] == ['auth', 'login']],
                         ['fixture-enterprise'])
        self.assertFalse([arguments for arguments, _ in calls if arguments[:2] == ['auth', 'switch']])

    def test_update_reseeds_every_account_and_the_default_active_account(self) -> None:
        calls = self.run_hook(list(TOKENS), update='1')
        self.assertEqual(len([1 for arguments, _ in calls if arguments[:2] == ['auth', 'login']]), 2)
        self.assertTrue([arguments for arguments, _ in calls if arguments[:2] == ['auth', 'switch']])

    def test_rejected_token_stops_without_revealing_it(self) -> None:
        def fake(arguments: list[str], text: str) -> subprocess.CompletedProcess[str]:
            code = 1 if arguments[1:3] == ['auth', 'login'] else 0
            return subprocess.CompletedProcess(arguments, code, '{"hosts": {}}', 'bad credentials')

        with patch.object(credentials.shutil, 'which', return_value='gh'), \
                patch.object(credentials, 'command', side_effect=fake):
            with self.assertRaises(ValueError) as raised:
                credentials.windows(TOKENS)
        self.assertNotIn('fixture-personal', str(raised.exception))


if __name__ == '__main__':
    unittest.main()
