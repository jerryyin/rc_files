import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import deploy


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
        return deploy.discover(self.repo, platform, destinations, [])

    def apply(self, links):
        problems = [deploy.problem(link) for link in links]
        self.assertFalse([problem for problem in problems if problem])
        for link in links:
            deploy.install(link, None)

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

    def test_untracked_runtime_and_metadata_are_excluded(self):
        self.write("editor/.editorrc")
        (self.repo / "editor/runtime.cache").write_text("runtime")
        self.write("editor/README.md", "documentation")
        self.write("private/.deploy-ignore", ".*")
        self.write("private/helper.py")
        self.write("README.md")
        self.assertEqual([link.target for link in self.plan()], [self.home / ".editorrc"])

    def test_existing_stow_ignore_is_respected(self):
        self.write("helpers/.stow-local-ignore", ".*")
        self.write("helpers/helper.sh")
        self.assertEqual(self.plan(), [])

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
            [sys.executable, str(Path(deploy.__file__)), "apply", "--repo", str(self.repo),
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
        self.assertFalse(deploy.matches(link))
        self.assertIsNone(deploy.problem(link))
        self.apply([link])
        self.assertTrue(deploy.matches(link))

    def test_source_move_repairs_only_owned_broken_links(self):
        source = self.write("editor/.editorrc")
        link = self.plan()[0]
        os.symlink(self.repo / "editor/old-name", link.target)
        self.assertIsNone(deploy.problem(link, repo=self.repo))
        link.target.unlink()
        os.symlink(self.root / "unrelated-missing-file", link.target)
        self.assertIn("Configuration conflict", deploy.problem(link, repo=self.repo))
        source.unlink()
        self.assertFalse(deploy.matches(link))

    def test_linked_destination_parent_is_not_traversed(self):
        self.write("editor/.config/editor/settings")
        outside = self.root / "outside"
        outside.mkdir()
        os.symlink(outside, self.home / ".config", target_is_directory=True)
        self.assertIn("Destination parent is a link", deploy.problem(self.plan()[0]))
        self.assertFalse((outside / "editor").exists())


if __name__ == "__main__":
    unittest.main()
