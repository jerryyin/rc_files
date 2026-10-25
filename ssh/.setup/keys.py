"""Local key permissions, explicit imports and existing-agent activation."""

from __future__ import annotations

import json
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess

from private import command, outside_git, write

PRIVATE_HEADER = re.compile(r'-----BEGIN (?:(?:OPENSSH|RSA|EC|DSA|ENCRYPTED) )?PRIVATE KEY-----')


def protect(paths: list[Path]) -> None:
    if not paths:
        return
    if os.name == 'nt':
        subprocess.run(['powershell.exe', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
                        '-File', str(Path(__file__).with_name('windows.ps1')), '-Protect'],
                       env=dict(os.environ, RC_SSH_PATHS=json.dumps([str(path) for path in paths])),
                       capture_output=True, check=True)
    else:
        for path in paths:
            path.chmod(0o700 if path.is_dir() else 0o644 if path.suffix == '.pub' else 0o600)


def private_keys(directory: Path) -> list[Path]:
    keys = []
    for path in sorted(directory.glob('id_*')):
        if path.is_file() and path.suffix != '.pub':
            with path.open(encoding='ascii', errors='replace') as stream:
                if PRIVATE_HEADER.fullmatch(stream.readline().strip()):
                    keys.append(path)
    return keys


def prepare_keys(directory: Path, source: Path | None) -> list[Path]:
    outside_git(directory.resolve())
    if os.name == 'nt' and (str(directory).startswith('\\\\') or (directory.exists() and
            directory.lstat().st_file_attributes & stat.FILE_ATTRIBUTE_REPARSE_POINT)):
        raise ValueError('Store Windows SSH keys in a local directory, outside links and Git')
    directory.mkdir(parents=True, exist_ok=True)
    protect([directory])
    if source is not None:
        if not source.is_dir():
            raise ValueError('SSH key source directory does not exist')
        for key in private_keys(source):
            target = directory / key.name
            if not os.path.lexists(target):
                write(target, key.read_text(encoding='ascii'))
            public = key.with_name(key.name + '.pub')
            public_target = target.with_name(target.name + '.pub')
            if (public.is_file() and not os.path.lexists(public_target)
                    and target.read_bytes() == key.read_bytes()):
                write(public_target, public.read_text(encoding='utf-8'))
    keys = private_keys(directory)
    for key in keys:
        outside_git(key.resolve())
        if os.name == 'nt' and key.is_symlink():
            raise ValueError('Windows private key files must not be links')
    protect(keys + [key.with_name(key.name + '.pub') for key in keys
                    if key.with_name(key.name + '.pub').is_file()])
    return keys


def without_passphrase(key: Path, keygen: str) -> bool:
    readable = command([keygen, '-y', '-P', '', '-f', str(key)], '').returncode == 0
    if not readable:
        print(f'SKIP SSH agent: unlock {key.name} yourself with ssh-add')
    return readable


def load_agent(keys: list[Path]) -> None:
    if not keys or os.environ.get('RC_SETUP_REDIRECTED') == '1':
        return
    directory = Path(os.environ['WINDIR']) / 'System32/OpenSSH' if os.name == 'nt' else None
    add = str(directory / 'ssh-add.exe') if directory else shutil.which('ssh-add')
    keygen = str(directory / 'ssh-keygen.exe') if directory else shutil.which('ssh-keygen')
    if not add or not keygen:
        raise ValueError('OpenSSH key tools are missing; run SSH setup first')
    loaded = command([add, '-l', '-E', 'sha256'], '')
    if loaded.returncode == 2:
        print('SKIP SSH agent: no agent available; keys remain usable directly')
        return
    if loaded.returncode not in (0, 1):
        raise ValueError('Cannot inspect the SSH agent')
    for key in keys:
        public = key.with_name(key.name + '.pub')
        has_public = public.is_file()
        if not has_public and not without_passphrase(key, keygen):
            continue
        fingerprint = command([keygen, '-lf', str(public if has_public else key), '-E', 'sha256'], '')
        if fingerprint.returncode or len(fingerprint.stdout.split()) < 2:
            raise ValueError(f'Cannot read SSH key fingerprint: {key.name}')
        if fingerprint.stdout.split()[1] in loaded.stdout:
            continue
        if has_public and not without_passphrase(key, keygen):
            continue
        if command([add, str(key)], '').returncode:
            raise ValueError(f'Cannot add SSH key to agent: {key.name}')
