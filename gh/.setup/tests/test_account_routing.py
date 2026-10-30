import importlib.machinery
import importlib.util
import json
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch

path = Path(__file__).resolve().parents[2] / '.linux/.local/bin/gh'
loader = importlib.machinery.SourceFileLoader('gh_routing', str(path))
spec = importlib.util.spec_from_loader(loader.name, loader)
routing = importlib.util.module_from_spec(spec)
loader.exec_module(routing)


class RoutingTests(unittest.TestCase):
    def test_explicit_repository_wins_over_current_context(self):
        for arguments in (['run', 'list', '-R', 'other/project'], ['run', 'list', '--repo=other/project'],
                          ['run', 'list', '-Rother/project'], ['repo', 'view', 'other/project'],
                          ['pr', 'view', 'https://github.com/other/project/pull/12']):
            with self.subTest(arguments=arguments):
                self.assertEqual(routing.repository_owner(arguments, {'GH_REPO': 'personal/repo'}), 'other')

    def test_current_repository_handles_ssh_and_https(self):
        for remote in ('git@github.com:personal/repo.git', 'https://github.com/personal/repo.git',
                       'ssh://git@github.com/personal/repo.git'):
            with patch.object(routing.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, remote, '')):
                self.assertEqual(routing.repository_owner(['run', 'list'], {}), 'personal')

    def test_api_endpoint_selects_owner_but_global_calls_and_other_hosts_do_not(self):
        self.assertEqual(routing.repository_owner(['api', 'repos/personal/repo/actions/runs'], {}), 'personal')
        for arguments, env in ((['auth', 'status'], {}), (['api', 'user'], {}),
                               (['api', 'repos/personal/repo', '--hostname=other.example'], {}),
                               (['run', 'list'], {'GH_HOST': 'other.example'})):
            self.assertIsNone(routing.repository_owner(arguments, env))

    def test_only_named_remote_works_without_origin(self):
        responses = [subprocess.CompletedProcess([], 1, '', ''), subprocess.CompletedProcess([], 1, '', ''),
                     subprocess.CompletedProcess([], 0, 'remote.private.url git@github.com:personal/repo.git\n', '')]
        with patch.object(routing.subprocess, 'run', side_effect=responses):
            self.assertEqual(routing.repository_owner(['run', 'list'], {}), 'personal')

    def test_explicit_gh_default_fork_wins_over_upstream_origin(self):
        responses = [subprocess.CompletedProcess([], 0, 'remote.private.gh-resolved base\n', ''),
                     subprocess.CompletedProcess([], 0, 'git@github.com:personal/repo.git\n', '')]
        with patch.object(routing.subprocess, 'run', side_effect=responses) as run:
            self.assertEqual(routing.repository_owner(['run', 'list'], {}), 'personal')
            self.assertEqual(run.call_args_list[-1].args[0], ['git', 'config', '--get', 'remote.private.url'])

    def test_multiple_non_origin_remotes_are_not_guessed(self):
        responses = [subprocess.CompletedProcess([], 1, '', ''), subprocess.CompletedProcess([], 1, '', ''), subprocess.CompletedProcess(
            [], 0, 'remote.private.url git@github.com:personal/repo.git\nremote.other.url git@github.com:work/repo.git\n', '')]
        with patch.object(routing.subprocess, 'run', side_effect=responses):
            self.assertIsNone(routing.repository_owner(['run', 'list'], {}))

    def account_calls(self, arguments, env, token_code=0):
        responses = [subprocess.CompletedProcess([], 0, json.dumps({'hosts': {'github.com': [
            {'login': 'personal', 'active': False}, {'login': 'work', 'active': True}]}}), ''),
            subprocess.CompletedProcess([], token_code, 'fixture-personal-token' if not token_code else '', '')]
        with patch.object(routing.subprocess, 'run', side_effect=responses) as run:
            result = routing.account_environment('/usr/bin/gh', arguments, env)
            return result, run.call_args_list

    def test_matching_owner_uses_per_process_token_without_global_switch(self):
        env = {'GH_REPO': 'personal/repo'}
        result, calls = self.account_calls(['run', 'list'], env)
        self.assertEqual(result['GH_TOKEN'], 'fixture-personal-token')
        self.assertNotIn('GH_TOKEN', env)
        self.assertEqual(calls[1].args[0], ['/usr/bin/gh', 'auth', 'token', '--hostname', 'github.com', '--user', 'personal'])
        self.assertEqual(len(calls), 2)

    def test_explicit_token_is_never_overridden(self):
        with patch.object(routing.subprocess, 'run') as run:
            env = {'GH_TOKEN': 'fixture-explicit', 'GH_REPO': 'personal/repo'}
            self.assertIs(routing.account_environment('/usr/bin/gh', ['run', 'list'], env), env)
            run.assert_not_called()

    def test_machine_queries_disable_forced_terminal_formatting_only_in_child(self):
        env = {'GH_REPO': 'personal/repo', 'GH_FORCE_TTY': '1', 'CLICOLOR_FORCE': '1'}
        result, calls = self.account_calls(['run', 'list'], env)
        self.assertEqual(calls[0].kwargs['env']['NO_COLOR'], '1')
        self.assertNotIn('GH_FORCE_TTY', calls[0].kwargs['env'])
        self.assertNotIn('CLICOLOR_FORCE', calls[1].kwargs['env'])
        self.assertEqual(result['GH_FORCE_TTY'], '1')

    def test_organization_does_not_guess_a_user(self):
        env = {'GH_REPO': 'organization/repo'}
        result, calls = self.account_calls(['run', 'list'], env)
        self.assertIs(result, env)
        self.assertEqual(len(calls), 1)

    def test_missing_owner_token_stops_instead_of_falling_back(self):
        with self.assertRaisesRegex(ValueError, 'no repository command was sent'):
            self.account_calls(['run', 'list'], {'GH_REPO': 'personal/repo'}, token_code=1)


if __name__ == '__main__':
    unittest.main()
