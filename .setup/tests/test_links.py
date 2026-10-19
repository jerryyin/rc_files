import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import links as deployment


class DeploymentTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="shared-deploy-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        self.repo = self.root / "a repository"
        self.home = self.root / "Someone's home"
        self.repo.mkdir()
        self.home.mkdir()
        self.git("init", "-q")

    def git(self, *arguments):
        environment = dict(os.environ, GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1")
        return subprocess.check_output(
            ["git", "-C", str(self.repo), "-c", "core.symlinks=true", *arguments],
            env=environment,
        )

    def write(self, name, content="authored configuration"):
        path = self.repo / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        self.git("add", "-f", "--", name)
        return path

    def alias(self, name, source):
        path = self.repo / name
        path.parent.mkdir(parents=True, exist_ok=True)
        os.symlink(os.path.relpath(source, path.parent), path, target_is_directory=source.is_dir())
        self.git("add", "-f", "--", name)
        return path

    def plan(self, platform="linux", **roots):
        destinations = {"HOME": self.home, "LOCALAPPDATA": self.home / "Local", **roots}
        return deployment.discover(self.repo, platform, destinations, [])

    def apply(self, links):
        problems = [deployment.problem(link) for link in links]
        self.assertFalse([problem for problem in problems if problem])
        for link in links:
            deployment.install(link, None)

    def test_shared_platform_override_and_root(self):
        common = self.write("editor/.editorrc", "shared")
        windows = self.write("editor/.windows/.editorrc", "Windows")
        self.write("editor/.windows/@LOCALAPPDATA/App/settings.json")
        linux = self.plan()
        native = self.plan("windows")
        self.assertEqual([(link.source, link.target) for link in linux], [(common, self.home / ".editorrc")])
        self.assertEqual({link.source for link in native}, {windows, self.repo / "editor/.windows/@LOCALAPPDATA/App/settings.json"})
        self.assertIn(self.home / "Local/App/settings.json", [link.target for link in native])

    def test_new_tracked_file_needs_no_deployer_change(self):
        self.write("editor/.editorrc")
        self.apply(self.plan())
        added = self.write("editor/.config/editor/new-setting")
        self.apply(self.plan())
        self.assertEqual((self.home / ".config/editor/new-setting").resolve(), added)

    def test_existing_link_through_a_git_alias_becomes_a_direct_source_link(self):
        source = self.write('editor/.editorrc')
        alias = self.alias('editor/.windows/_editorrc', source)
        alias.unlink()
        alias.write_text('../.editorrc')
        target = self.home / '_editorrc'
        target.symlink_to(alias)
        link = next(link for link in self.plan('windows') if link.target == target)
        self.assertIsNone(deployment.problem(link, repo=self.repo))
        backup = self.root / 'backup'
        deployment.install(link, backup)
        self.assertEqual(Path(os.readlink(target).removeprefix('\\\\?\\')), source)
        target.write_text('saved through direct link')
        self.assertEqual(source.read_text(), 'saved through direct link')
        self.assertTrue(any(path.is_symlink() for path in backup.iterdir()))
        before = target.lstat().st_mtime_ns
        deployment.install(link, backup)
        self.assertEqual(target.lstat().st_mtime_ns, before)

    def test_untracked_runtime_and_metadata_are_excluded(self):
        self.write("editor/.editorrc")
        (self.repo / "editor/runtime.cache").write_text("runtime")
        self.write(".setup/README.md", "documentation")
        self.write(".setup/helper.py")
        self.write("README.md")
        self.assertEqual([link.target for link in self.plan()], [self.home / ".editorrc"])

    def test_hidden_utilities_are_not_packages(self):
        self.write(".helpers/helper.sh")
        self.assertEqual(self.plan(), [])

    def test_package_setup_is_reserved_at_the_package_root(self):
        source = self.write('editor/.editorrc')
        self.write('editor/.setup/__main__.py')
        self.write('editor/.setup/tests/test_setup.py')
        self.write('editor/.setup/driver.vim')
        self.write('editor/.windows/.setup/helper.py')
        self.write('editor/.linux/.setup/helper.py')
        native = self.write('editor/.config/editor/.setup')
        for platform in ('linux', 'windows'):
            with self.subTest(platform=platform):
                plan = {link.target: link.source for link in self.plan(platform)}
                self.assertEqual(plan, {self.home / '.editorrc': source,
                                        self.home / '.config/editor/.setup': native})

    def test_file_edits_and_repeat_apply(self):
        source = self.write("editor/.editorrc")
        links = self.plan()
        self.apply(links)
        target = self.home / ".editorrc"
        timestamp = target.lstat().st_mtime_ns
        target.write_text("edited through installed link")
        self.apply(links)
        self.assertEqual(source.read_text(), "edited through installed link")
        self.assertEqual(timestamp, target.lstat().st_mtime_ns)
        self.assertFalse((self.home / ".config").exists())

    def test_no_directory_folding(self):
        self.write("editor/.config/editor/settings")
        self.apply(self.plan())
        (self.home / ".config/editor/cache").write_text("runtime")
        self.assertFalse((self.home / ".config").is_symlink())
        self.assertFalse((self.repo / "editor/.config/editor/cache").exists())

    def test_aliases_work_even_when_git_checks_out_text(self):
        source = self.write("editor/.editorrc")
        alias = self.alias("editor/.windows/_editorrc", source)
        value = os.readlink(alias)
        alias.unlink()
        alias.write_text(value)
        links = self.plan("windows")
        self.apply(links)
        self.assertEqual((self.home / "_editorrc").resolve(), source)

    def test_directory_alias_adds_skills_without_a_list(self):
        source = self.write("agent/.skills/first/SKILL.md").parent
        self.alias("agent/.windows/.agents/skills.links", source.parent)
        links = self.plan("windows")
        self.apply(links)
        target = self.home / ".agents/skills/first"
        (target / "helper.py").write_text("new helper")
        self.assertTrue((source / "helper.py").is_file())
        replacement = target / "SKILL.new"
        replacement.write_text("atomic editor save")
        os.replace(replacement, target / "SKILL.md")
        self.assertEqual((source / "SKILL.md").read_text(), "atomic editor save")
        self.write("agent/.skills/second/SKILL.md")
        self.apply(self.plan("windows"))
        self.assertTrue((self.home / ".agents/skills/second").is_symlink())

    def test_conflict_preflight_changes_nothing(self):
        self.write("editor/a-new")
        self.write("editor/z-conflict")
        target = self.home / "z-conflict"
        target.write_text("local edits")
        output = subprocess.run(
            [sys.executable, str(Path(deployment.__file__).parent), "apply", "--repo", str(self.repo),
             "--home", str(self.home), "--platform", "linux", "--json"],
            capture_output=True, text=True,
        )
        self.assertEqual(output.returncode, 1)
        self.assertIn("Configuration conflict", json.loads(output.stdout)["problems"][0])
        self.assertFalse((self.home / "a-new").exists())
        self.assertEqual(target.read_text(), "local edits")

    def test_duplicate_targets_are_rejected(self):
        self.write("one/.config/editor/settings", "one")
        self.write("two/.config/editor/settings", "two")
        with self.assertRaisesRegex(ValueError, "Two package files"):
            self.plan()

    def test_root_override_redirects_a_subtree(self):
        self.write("editor/.windows/@LOCALAPPDATA/Packaged/App/settings")
        alternate = self.home / "Alternate"
        links = self.plan("windows", **{"LOCALAPPDATA/Packaged/App": alternate})
        self.assertEqual(links[0].target, alternate / "settings")

    def test_detached_identical_copy_fails_check(self):
        self.write("editor/.editorrc")
        link = self.plan()[0]
        link.target.write_text(link.source.read_text())
        self.assertFalse(deployment.matches(link))
        self.assertIsNone(deployment.problem(link))
        self.apply([link])
        self.assertTrue(deployment.matches(link))

    def test_source_move_repairs_only_owned_broken_links(self):
        source = self.write("editor/.editorrc")
        link = self.plan()[0]
        os.symlink(self.repo / "editor/old-name", link.target)
        self.assertIsNone(deployment.problem(link, repo=self.repo))
        link.target.unlink()
        os.symlink(self.root / "unrelated-missing-file", link.target)
        self.assertIn("Configuration conflict", deployment.problem(link, repo=self.repo))
        source.unlink()
        self.assertFalse(deployment.matches(link))

    def test_linked_destination_parent_is_not_traversed(self):
        self.write("editor/.config/editor/settings")
        outside = self.root / "outside"
        outside.mkdir()
        os.symlink(outside, self.home / ".config", target_is_directory=True)
        self.assertIn("Destination parent is a link", deployment.problem(self.plan()[0]))
        self.assertFalse((outside / "editor").exists())

    def test_directory_link_convention_uses_real_source_directories(self):
        source = self.write('agent/.agents/skills.links/first/SKILL.md').parent
        links = self.plan()
        self.assertEqual(links, [deployment.Link(source, self.home / '.agents/skills/first', True)])
        self.apply(links)
        (self.home / '.agents/skills/first/helper.py').write_text('new helper')
        self.assertTrue((source / 'helper.py').exists())

    def test_migration_unfolds_owned_directories_and_preserves_runtime(self):
        source = self.write('editor/.config/editor/settings')
        runtime = source.parent / 'runtime.cache'
        runtime.write_text('preserved runtime')
        os.symlink(self.repo / 'editor/.config', self.home / '.config', target_is_directory=True)
        links = self.plan()
        backup = self.root / 'backups'
        deployment.migrate_parents(links, self.repo, self.home, backup)
        self.apply(links)
        self.assertFalse((self.home / '.config').is_symlink())
        self.assertTrue(deployment.matches(links[0]))
        self.assertEqual((self.home / '.config/editor/runtime.cache').read_text(), 'preserved runtime')
        self.assertFalse(runtime.exists())
        count = len(list(backup.rglob('*')))
        deployment.migrate_parents(links, self.repo, self.home, backup)
        self.assertEqual(count, len(list(backup.rglob('*'))))

    def test_migration_removes_a_retired_alias_and_keeps_its_shared_source(self):
        source = self.write('editor/.editorrc')
        alias = self.alias('editor/.windows/_editorrc', source)
        self.apply(self.plan('windows'))
        retired = self.home / '_editorrc'
        self.git('rm', '-f', '--', str(alias.relative_to(self.repo)))
        links = self.plan('windows')
        backup = self.root / 'backups'
        deployment.prune_links(links, self.repo, self.home, backup)
        self.assertFalse(os.path.lexists(retired))
        self.assertEqual((self.home / '.editorrc').resolve(), source)
        self.assertEqual((backup / 'links/_editorrc').resolve(), source)
        count = len(list(backup.rglob('*')))
        self.apply(links)
        deployment.prune_links(links, self.repo, self.home, backup)
        self.assertFalse(os.path.lexists(retired))
        self.assertEqual(len(list(backup.rglob('*'))), count)

    def test_migration_prunes_foreign_platform_subtrees_without_removing_local_data(self):
        self.write('editor/.config/current/settings')
        retired = self.write('editor/.config/retired/lua/settings.lua')
        self.apply(self.plan('windows'))
        local = self.home / '.config/retired/local.json'
        local.write_text('local runtime data')
        self.git('rm', '-f', '--', str(retired.relative_to(self.repo)))
        self.write('editor/.linux/.config/retired/lua/settings.lua')
        backup = self.root / 'backups'
        links = self.plan('windows')
        deployment.prune_links(links, self.repo, self.home, backup, self.plan('linux'))
        self.assertFalse(os.path.lexists(local.parent / 'lua/settings.lua'))
        self.assertFalse((local.parent / 'lua').exists())
        self.assertEqual(local.read_text(), 'local runtime data')
        self.assertTrue(os.path.lexists(backup / 'links/.config/retired/lua/settings.lua'))
        self.assertTrue((self.home / '.config/current/settings').is_symlink())
        count = len(list(backup.rglob('*')))
        deployment.prune_links(links, self.repo, self.home, backup, self.plan('linux'))
        self.assertEqual(len(list(backup.rglob('*'))), count)

    def test_migration_keeps_home_when_all_configuration_belongs_to_another_platform(self):
        self.write('editor/.linux/.editorrc')
        self.apply(self.plan('linux'))
        deployment.prune_links([], self.repo, self.home, self.root / 'backups', self.plan('linux'))
        self.assertTrue(self.home.is_dir())
        self.assertFalse(os.path.lexists(self.home / '.editorrc'))

    def test_migration_prunes_retired_directory_beside_current_configuration(self):
        self.write('editor/.editor/current')
        old = self.write('editor/.editor/rules/old.md')
        self.apply(self.plan())
        local = self.home / '.editor/rules/local.md'
        local.write_text('untracked local note')
        self.git('rm', '-f', '--', str(old.relative_to(self.repo)))
        links = self.plan()
        backup = self.root / 'backups'
        deployment.prune_links(links, self.repo, self.home, backup)
        self.assertFalse(os.path.lexists(local.parent / 'old.md'))
        self.assertEqual(local.read_text(), 'untracked local note')
        self.assertTrue(os.path.lexists(backup / 'links/.editor/rules/old.md'))
        before = len(list(backup.rglob('*')))
        deployment.prune_links(links, self.repo, self.home, backup)
        self.assertEqual(len(list(backup.rglob('*'))), before)

    def test_migration_does_not_search_unmanaged_home_or_deep_runtime_directories(self):
        self.write('editor/.editor/current')
        self.apply(self.plan())
        for name in ('unrelated/old', '.editor/runtime/nested/old'):
            target = self.home / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.symlink_to(self.repo / 'editor/missing')
        deployment.prune_links(self.plan(), self.repo, self.home, self.root / 'backups')
        self.assertTrue(os.path.lexists(self.home / 'unrelated/old'))
        self.assertTrue(os.path.lexists(self.home / '.editor/runtime/nested/old'))


if __name__ == "__main__":
    unittest.main()
