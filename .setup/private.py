"""Private file operations shared by package-owned credential hooks."""

from __future__ import annotations

from collections.abc import Callable
import filecmp
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


def run(action: Callable[[], None]) -> None:
    try:
        action()
    except (UnicodeError, subprocess.CalledProcessError):
        print('Credentials: input or helper failed; secret diagnostics were suppressed', file=sys.stderr)
        sys.exit(1)
    except (OSError, ValueError) as error:
        print(f'Credentials: {error}', file=sys.stderr)
        sys.exit(1)


def location(variable: str, default: Path) -> Path:
    path = Path(os.environ.get(variable, str(default))).expanduser().absolute()
    if os.environ.get('RC_SETUP_REDIRECTED') == '1' and not path.resolve().is_relative_to(Path.home().resolve()):
        # Persistent storage is explicitly passed separately; inherited overrides
        # must not escape an acceptance test's redirected home.
        raise ValueError(f'{variable} must be inside its test home')
    return path


def secret(variable: str, name: str) -> str | None:
    vault = Path(os.environ.get('RC_CREDENTIALS_VAULT', str(Path.home() / 'vault')))
    path = location(variable, vault / name) if variable in os.environ else vault / name
    if not path.exists():
        print(f'SKIP: {name} is absent; existing credentials preserved')
        return None
    value = path.read_text(encoding='utf-8-sig').strip()
    if not value or not value.isascii() or not value.isprintable() or any(c.isspace() for c in value):
        raise ValueError(f'{name} must contain one nonempty printable ASCII token')
    return value


def outside_git(path: Path) -> None:
    if any((parent / '.git').exists() for parent in (path, *path.parents)):
        raise ValueError('Private destinations must be outside Git checkouts')


def protect(path: Path) -> None:
    if os.name != 'nt':
        path.chmod(0o600)
        return
    script = '''$ErrorActionPreference = 'Stop'
$sid = [Security.Principal.WindowsIdentity]::GetCurrent().User
$acl = New-Object Security.AccessControl.FileSecurity
$acl.SetOwner($sid)
$acl.SetAccessRuleProtection($true, $false)
foreach ($identity in @($sid.Value, 'S-1-5-18', 'S-1-5-32-544')) {
    $principal = New-Object Security.Principal.SecurityIdentifier($identity)
    $acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule($principal, 'FullControl', 'Allow')))
}
(Get-Item -LiteralPath $env:RC_PRIVATE_PATH -Force).SetAccessControl($acl)
'''
    subprocess.run(['powershell.exe', '-NoProfile', '-NonInteractive', '-Command', script],
                   env=dict(os.environ, RC_PRIVATE_PATH=str(path)), check=True, capture_output=True)


def write(path: Path, text: str) -> None:
    outside_git(path.parent.resolve())
    target = path.resolve()
    detached = False
    if path.is_symlink():
        repo = Path(os.environ.get('RC_SETUP_REPO', str(Path(__file__).resolve().parents[1])))
        if target.is_relative_to(repo):
            target = path  # Detach obsolete repository-owned credential links.
            detached = True
        else:
            outside_git(target)
    outside_git(target.parent.resolve())
    if target.exists() and not detached and target.read_text(encoding='utf-8-sig') == text:
        protect(target)
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode='w', encoding='utf-8', newline='\n',
                                         dir=target.parent, delete=False) as stream:
            temporary = Path(stream.name)
            protect(temporary)
            stream.write(text)
        os.replace(temporary, target)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    try:
        result = json.loads(path.read_text(encoding='utf-8-sig'))
    except json.JSONDecodeError:
        raise ValueError(f'Invalid JSON in {path}; file preserved') from None
    if not isinstance(result, dict):
        raise ValueError(f'{path} must contain a JSON object')
    return result


def command(arguments: list[str], text: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(arguments, input=text, capture_output=True, text=True, encoding='utf-8', check=False)


def same(source: Path, target: Path) -> bool:
    if source.is_symlink() or target.is_symlink():
        return False
    if source.is_file() and target.is_file():
        return source.read_bytes() == target.read_bytes()
    if not source.is_dir() or not target.is_dir():
        return False
    comparison = filecmp.dircmp(source, target)
    return (not comparison.left_only and not comparison.right_only and not comparison.funny_files
            and all(same(source / name, target / name) for name in comparison.common))


def copy_private(source: Path, target: Path) -> None:
    outside_git(target.resolve())
    if source.is_symlink():
        raise ValueError('Refusing to copy linked credential content')
    if source.is_dir():
        target.mkdir(parents=True, exist_ok=True)
        if os.name != 'nt':
            target.chmod(0o700)
        for child in source.iterdir():
            copy_private(child, target / child.name)
    else:
        write(target, source.read_text(encoding='utf-8-sig'))


def persist(relative: str) -> None:
    root = os.environ.get('RC_CREDENTIALS_ROOT', '')
    if not root or os.name == 'nt':
        return
    local, stored = Path.home() / relative, Path(root) / relative
    outside_git(local.parent.resolve())
    outside_git(stored.resolve())
    if local.resolve() == stored.resolve():
        return
    save = os.environ.get('RC_CREDENTIALS_SAVE') == '1'
    source, target = (local, stored) if save else (stored, local)
    if not source.exists():
        return
    if not save and source.is_file():
        protect(source)
    if local.exists() and stored.exists() and not same(local, stored) and not save:
        print(f'SKIP: {relative} differs locally; authenticate or save explicitly to reconcile')
        return
    if save:
        copy_private(source, target)
    if local.is_symlink():
        local.unlink()
    elif local.is_dir():
        shutil.rmtree(local)
    elif local.exists():
        local.unlink()
    local.parent.mkdir(parents=True, exist_ok=True)
    local.symlink_to(stored, target_is_directory=stored.is_dir())
