from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import links as deployment


class AgentConfigurationTests(unittest.TestCase):
    def setUp(self):
        original = Path(__file__).resolve().parents[2]
        temporary = tempfile.TemporaryDirectory(prefix='agent-configuration-')
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name).resolve()
        self.repo = self.root / 'relocated rc files'
        self.repo.mkdir()
        shutil.copytree(original / 'agents', self.repo / 'agents', symlinks=True)
        shutil.copyfile(original / '.gitignore', self.repo / '.gitignore')
        subprocess.run(['git', '-C', str(self.repo), 'init', '-q'], check=True)
        subprocess.run(['git', '-C', str(self.repo), '-c', 'core.symlinks=true', '-c', 'core.autocrlf=false',
                        'add', '-f', '--', 'agents'], check=True)
        self.source = self.repo / 'agents/.agents'
        self.skills = {path.parent.name for path in (self.source / 'skills.links').glob('*/SKILL.md')}
        self.assertTrue(self.skills)

    def assert_collection(self, plan, home):
        by_target = {link.target.relative_to(home).as_posix(): link for link in plan}
        for target in ('.agents/AGENTS.md', '.codex/AGENTS.md', '.claude/CLAUDE.md'):
            self.assertEqual(by_target[target].source, self.source / 'AGENTS.md')
        self.assertFalse(any(target.startswith('.claude/rules/') for target in by_target))
        for prefix in ('.agents/skills/', '.claude/skills/'):
            self.assertEqual({name.removeprefix(prefix) for name in by_target
                              if name.startswith(prefix)}, self.skills)
            for name in self.skills:
                link = by_target[prefix + name]
                self.assertTrue(link.directory)
                self.assertEqual(link.source, self.source / 'skills.links' / name)

    def test_tracked_collection_deploys_from_a_relocated_checkout(self):
        for platform in ('linux', 'windows'):
            with self.subTest(platform=platform):
                home = self.root / platform
                plan = deployment.discover(self.repo, platform, {'HOME': home}, ['agents'])
                self.assert_collection(plan, home)
                for link in plan:
                    deployment.install(link, None)
                before = {link.target: link.target.lstat().st_mtime_ns for link in plan}
                for link in plan:
                    self.assertTrue(deployment.matches(link))
                    deployment.install(link, None)
                self.assertEqual(before, {link.target: link.target.lstat().st_mtime_ns for link in plan})
                helper = home / '.agents/skills' / sorted(self.skills)[0] / 'local-helper.txt'
                helper.write_text('saved through installed skill', encoding='utf-8')
                self.assertTrue(helper.resolve().is_relative_to(self.source))
                self.assertIn('local-helper.txt', subprocess.check_output(
                    ['git', '-C', str(self.repo), 'status', '--short', '--untracked-files=all'], text=True))
                helper.unlink()

    def test_conditional_rules_have_portable_scope_outside_native_loaders(self):
        rules = list((self.source / 'rules').glob('*.md'))
        self.assertTrue(rules)
        for path in rules:
            with self.subTest(rule=path.name):
                content = path.read_text(encoding='utf-8')
                self.assertTrue(content.startswith('# '))
                self.assertTrue(any(line.startswith('Applies when:') for line in content.splitlines()))
                self.assertNotRegex(content, r'(?m)^(globs|paths):')
        skill = self.source / 'skills.links/initiate-campaign'
        self.assertTrue((skill / 'references/wake-prompt.md').is_file())
        self.assertIn('references/wake-prompt.md', (skill / 'SKILL.md').read_text(encoding='utf-8'))

    def test_authored_additions_preserve_global_generated_file_exclusions(self):
        excludes = Path(__file__).resolve().parents[2] / 'git/.gitignore'
        command = ['git', '-C', str(self.repo), '-c', 'core.excludesfile=' + str(excludes),
                   'check-ignore', '--no-index', '--quiet']
        for name in ('rules/new-rule.md', 'skills.links/new-skill/SKILL.md',
                     'skills.links/new-skill/helper.py'):
            with self.subTest(authored=name):
                self.assertEqual(subprocess.run([*command, str(self.source / name)]).returncode, 1)
        for name in ('rules/.rule.md.swp', 'skills.links/new-skill/.helper.py.swp',
                     'skills.links/new-skill/tags', 'skills.links/new-skill/cscope.out'):
            with self.subTest(generated=name):
                self.assertEqual(subprocess.run([*command, str(self.source / name)]).returncode, 0)


if __name__ == '__main__':
    unittest.main()
