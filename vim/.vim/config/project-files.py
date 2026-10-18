"""List project files for the Vim and Neovim file pickers."""

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys


def untracked_files(directory: Path) -> list[str]:
    if shutil.which('rg'):
        command = ['rg', '--files', '--null', '--path-separator', '/', '--glob', '!build/**']
    else:
        command = ['ag', '-g', '.', '--null', '--nocolor', '--ignore', '/build/']
    result = subprocess.run(command, cwd=directory, stdin=subprocess.DEVNULL,
                            stdout=subprocess.PIPE)
    if result.returncode != 1:
        result.check_returncode()
    return result.stdout.decode('utf-8').split('\0')[:-1]


def project_files(directory: Path) -> list[str]:
    probe = subprocess.run(['git', 'rev-parse', '--is-inside-work-tree'], cwd=directory,
                           env=dict(os.environ, LC_ALL='C'), capture_output=True)
    if probe.returncode and b'not a git repository (or any' not in probe.stderr:
        raise RuntimeError(probe.stderr.decode('utf-8').strip())
    if probe.returncode == 0 and probe.stdout.strip() == b'true':
        result = subprocess.run(['git', 'ls-files', '--recurse-submodules', '-z'],
                                cwd=directory, stdout=subprocess.PIPE, check=True)
        files = result.stdout.decode('utf-8').split('\0')[:-1]
        files.extend(path.relative_to(directory).as_posix()
                     for path in (directory / 'build').rglob('*.inc')
                     if path.name.endswith('.inc'))
    else:
        files = untracked_files(directory)
    if any((directory / name).is_dir() for name in ('iree', 'compiler/src/iree', 'runtime/src/iree')):
        return [name for name in files if not name.startswith('third_party/')
                or name.startswith('third_party/llvm-project/mlir/')]
    if any((directory / name).is_dir() for name in ('python/triton', 'include/triton')):
        return [name for name in files
                if not name.startswith(('third_party/f2reduce/', 'third_party/nvidia/'))]
    return files


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory', nargs='?', type=Path, default=Path('.'))
    arguments = parser.parse_args()
    files = project_files(arguments.directory.resolve())
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stdout.write(''.join(name + '\n' for name in files))
