import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


@unittest.skipUnless(sys.platform == 'linux' and shutil.which('gdb'), 'Linux GDB required')
class PrinterTests(unittest.TestCase):
    def test_only_present_printers_load(self) -> None:
        config = Path(__file__).resolve().parents[2] / '.gdbinit'
        for projects in ((), ('llvm',), ('mlir',), ('llvm', 'mlir')):
            with self.subTest(projects=projects), tempfile.TemporaryDirectory(prefix='gdb-') as root:
                home = Path(root) / "Someone's home"
                home.mkdir()
                for project in projects:
                    printer = home / 'iree/third_party/llvm-project' / project / 'utils/gdb-scripts/prettyprinters.py'
                    printer.parent.mkdir(parents=True)
                    printer.write_text(f'import gdb\ngdb.write("loaded {project}\\n")\n')
                result = subprocess.run(['gdb', '-nx', '-nh', '-batch', '-ex', 'source ' + str(config),
                                         '-ex', 'python print("pretty=" + str(gdb.parameter("print pretty")))',
                                         '-ex', 'python print("object=" + str(gdb.parameter("print object")))'],
                                        env=dict(os.environ, HOME=str(home)),
                                        text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual(result.stderr, '')
                for project in ('llvm', 'mlir'):
                    self.assertEqual(f'loaded {project}\n' in result.stdout, project in projects)
                self.assertIn('pretty=True', result.stdout)
                self.assertIn('object=True', result.stdout)


if __name__ == '__main__':
    unittest.main()
