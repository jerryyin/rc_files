"""Credential selection never combines work and home inputs."""

import os
import unittest

from test_credentials import CredentialFixture


class VaultScopeTests(CredentialFixture):
    def select(self, scope: str) -> list[str]:
        (self.vault / '.vault-scope').write_text(scope + '\n')
        return ['--vault', str(self.vault), '--vault-scope', scope]

    @unittest.skipIf(os.name == 'nt', 'Linux GitHub account file')
    def test_each_scope_renders_only_its_github_account(self) -> None:
        self.copy_package('gh')
        for scope, name, login in (('work', 'amdeng', 'zhuoryin_amdeng'),
                                   ('homelab', 'jerryyin', 'jerryyin')):
            arguments = self.select(scope)
            token = self.vault / f'gh_token_{name}.txt'
            token.write_text(f'fixture-{scope}')
            path = self.home / '.config/gh/hosts.yml'
            path.unlink(missing_ok=True)
            self.ok(*arguments)
            content = path.read_text()
            self.assertIn(f'user: {login}', content)
            self.assertIn(f'fixture-{scope}', content)
            self.assertNotIn('jerryyin' if scope == 'work' else 'zhuoryin_amdeng', content)
            token.unlink()

    def test_wrong_scope_and_mixed_vault_fail_before_hooks(self) -> None:
        self.write('app/.setup/credentials.py', 'raise SystemExit(99)')
        self.select('homelab')
        result = self.invoke('--vault', str(self.vault), '--vault-scope', 'work')
        self.assertIn('Vault scope mismatch', result.stderr)
        arguments = self.select('work')
        (self.vault / 'navidrome_admin.txt').write_text('fixture-private-value')
        result = self.invoke(*arguments)
        self.assertNotEqual(result.returncode, 99)
        self.assertIn('does not belong in work', result.stderr)
        self.assertNotIn('fixture-private-value', result.stdout + result.stderr)

    def test_unmarked_vault_is_not_accepted_as_a_new_scope(self) -> None:
        self.write('app/.setup/credentials.py', 'raise SystemExit(99)')
        (self.vault / '.vault-scope').unlink()
        result = self.invoke('--vault', str(self.vault), '--vault-scope', 'homelab')
        self.assertIn('Missing .vault-scope', result.stderr)

    def test_home_does_not_import_work_token_from_environment_override(self) -> None:
        self.copy_package('artifactory')
        token = self.home / 'outside-work-token'
        token.write_text('fixture-work-token')
        self.environment['ARTIFACTORY_KEY_FILE'] = str(token)
        self.ok(*self.select('homelab'))
        self.assertFalse((self.home / '.netrc').exists())

    @unittest.skipIf(os.name == 'nt', 'Linux gist configuration')
    def test_home_gist_token_rotates_without_importing_work_credentials(self) -> None:
        self.copy_package('gist')
        arguments = self.select('homelab')
        for token in ('fixture-first', 'fixture-rotated'):
            (self.vault / 'gh_token_jerryyin.txt').write_text(token)
            self.assertNotIn(token, self.ok(*arguments))
            self.assertEqual((self.home / '.gist').read_text(), token + '\n')


if __name__ == '__main__':
    unittest.main()
