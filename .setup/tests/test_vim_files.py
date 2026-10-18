import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


class LeaderfFilesTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix='vim-files-')
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name).resolve()
        self.project = self.root / "Someone's project"
        self.project.mkdir()
        self.helper = Path(__file__).resolve().parents[2] / 'vim/.vim/config/leaderf-files.py'
        self.environment = dict(os.environ, GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM='1')

    def git(self, *arguments: str, directory: Path | None = None) -> None:
        subprocess.run(['git', '-C', str(directory or self.project), *arguments],
                       env=self.environment, check=True, capture_output=True)

    def write(self, name: str) -> None:
        target = self.project / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text('fixture\n', encoding='utf-8')

    def files(self) -> set[str]:
        result = subprocess.run([sys.executable, str(self.helper), str(self.project)],
                                env=self.environment, text=True, encoding='utf-8',
                                capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return set(result.stdout.splitlines())

    def test_git_files_and_generated_includes(self) -> None:
        self.git('init', '-q')
        for name in ('source file.cpp', 'naïve.cpp', 'src/main.cpp'):
            self.write(name)
        self.git('add', '-f', '--all')
        for name in ('untracked.cpp', 'build/generated/header.inc', 'build/other.o'):
            self.write(name)
        self.assertEqual(self.files(), {'source file.cpp', 'naïve.cpp', 'src/main.cpp',
                                        'build/generated/header.inc'})

    def test_existing_iree_filter(self) -> None:
        self.git('init', '-q')
        for name in ('main.cpp', 'iree/compiler.cpp', 'third_party/llvm-project/mlir/pass.cpp',
                     'third_party/llvm-project/llvm/pass.cpp', 'third_party/other/file.cpp',
                     'tools/tool.cpp', 'tests/test.cpp'):
            self.write(name)
        self.git('add', '-f', '--all')
        self.assertEqual(self.files(), {'main.cpp', 'iree/compiler.cpp',
                                        'third_party/llvm-project/mlir/pass.cpp'})

    def test_triton_filter(self) -> None:
        self.git('init', '-q')
        included = {'python/triton/main.py', 'third_party/amd/file.cpp',
                    'third_party/proton/file.cpp', 'third_party/nvidia-extra/file.cpp'}
        for name in included | {'third_party/f2reduce/file.cpp', 'third_party/nvidia/file.cpp'}:
            self.write(name)
        self.git('add', '-f', '--all')
        self.assertEqual(self.files(), included)

    def test_submodule_files(self) -> None:
        library = self.root / 'library'
        library.mkdir()
        (library / 'library.cpp').write_text('fixture\n')
        self.git('init', '-q', directory=library)
        self.git('add', '-f', '--all', directory=library)
        self.git('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
                 'commit', '-qm', 'Fixture', directory=library)
        self.git('init', '-q')
        self.git('-c', 'protocol.file.allow=always', 'submodule', 'add', '-q',
                 str(library), 'vendor library')
        self.assertEqual(self.files(), {'.gitmodules', 'vendor library/library.cpp'})

    def test_non_git_folder_respects_ignores_and_excludes_root_build(self) -> None:
        self.write('src/source file.cpp')
        self.write('nested/build/keep.cpp')
        self.write('build/generated.inc')
        self.write('ignored.cpp')
        (self.project / '.ignore').write_text('ignored.cpp\n')
        self.assertEqual(self.files(), {'src/source file.cpp', 'nested/build/keep.cpp'})

    def test_empty_non_git_folder(self) -> None:
        self.assertEqual(self.files(), set())

    def test_invalid_git_directory_is_an_error(self) -> None:
        (self.project / '.git').write_text('gitdir: missing-repository\n')
        self.write('source.cpp')
        result = subprocess.run([sys.executable, str(self.helper), str(self.project)],
                                env=self.environment, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, b'')
        self.assertIn(b'not a git repository:', result.stderr)


if __name__ == '__main__':
    unittest.main()
