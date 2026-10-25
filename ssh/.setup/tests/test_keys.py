import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / '.setup'))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import keys


class AgentTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix='ssh-agent-test-')
        self.addCleanup(temporary.cleanup)
        self.key = Path(temporary.name) / 'id_test'
        self.public = self.key.with_name('id_test.pub')
        self.public.write_text('fixture public key')
        environment = patch.dict(os.environ, RC_SETUP_REDIRECTED='0')
        environment.start()
        self.addCleanup(environment.stop)

    def replies(self, *responses: tuple[int, str]) -> Mock:
        helper = Mock(side_effect=[subprocess.CompletedProcess([], code, text, '') for code, text in responses])
        replacement = patch.object(keys, 'command', helper)
        replacement.start()
        self.addCleanup(replacement.stop)
        return helper

    def agent_changes(self, helper: Mock) -> list[list[str]]:
        return [call.args[0][1:] for call in helper.call_args_list
                if Path(call.args[0][0]).stem == 'ssh-add' and call.args[0][1] != '-l']

    def test_loaded_key_is_not_added_again(self) -> None:
        helper = self.replies((0, '256 SHA256:fixture existing key'), (0, '256 SHA256:fixture key'))
        keys.load_agent([self.key])
        self.assertEqual(self.agent_changes(helper), [])

    def test_locked_key_never_opens_a_passphrase_prompt(self) -> None:
        helper = self.replies((1, ''), (0, '256 SHA256:fixture key'), (1, ''))
        keys.load_agent([self.key])
        self.assertEqual(self.agent_changes(helper), [])
        self.assertEqual(helper.call_args.args[0][-4:], ['-P', '', '-f', str(self.key)])

    def test_unlocked_key_is_loaded_into_existing_agent(self) -> None:
        helper = self.replies((1, ''), (0, '256 SHA256:fixture key'), (0, 'public key'), (0, ''))
        keys.load_agent([self.key])
        self.assertEqual(self.agent_changes(helper), [[str(self.key)]])

    def test_absent_agent_preserves_direct_key_use(self) -> None:
        helper = self.replies((2, ''))
        keys.load_agent([self.key])
        self.assertEqual(self.agent_changes(helper), [])
        self.assertFalse(any('-lf' in call.args[0] for call in helper.call_args_list))

    def test_locked_key_without_public_pair_never_attempts_interactive_fingerprinting(self) -> None:
        helper = self.replies((1, ''), (1, ''))
        self.public.unlink()
        keys.load_agent([self.key])
        self.assertEqual(self.agent_changes(helper), [])
        self.assertFalse(any('-lf' in call.args[0] for call in helper.call_args_list))
        self.assertEqual(helper.call_args.args[0][-4:], ['-P', '', '-f', str(self.key)])


if __name__ == '__main__':
    unittest.main()
