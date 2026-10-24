"""Install native packages and discover their executables."""

from __future__ import annotations

from dataclasses import asdict, dataclass
import ctypes
import glob
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

if os.name == 'nt':
    import winreg


@dataclass(frozen=True)
class Package:
    command: str = ''
    apt: tuple[str, ...] = ()
    winget: str = ''
    scope: str = 'machine'
    arguments: str = ''
    minimum: tuple[int, ...] = ()
    search: tuple[str, ...] = ()
    exclude: str = ''
    installer_type: str = ''
    provisioned: str = ''
    npm: str = ''


def refresh_path() -> None:
    paths = os.environ.get('PATH', '').split(os.pathsep)
    paths.insert(0, str(Path.home() / '.local/bin'))
    if os.name == 'nt':
        shared = [str(Path(os.environ['ProgramFiles']) / 'npm')]
        for hive, key in ((winreg.HKEY_LOCAL_MACHINE,
                           r'SYSTEM\CurrentControlSet\Control\Session Manager\Environment'),
                          (winreg.HKEY_CURRENT_USER, 'Environment')):
            with winreg.OpenKey(hive, key) as handle:
                try:
                    value = winreg.QueryValueEx(handle, 'Path')[0]
                except FileNotFoundError:
                    continue
                target = shared if hive == winreg.HKEY_LOCAL_MACHINE else paths
                target.extend(os.path.expandvars(value).split(os.pathsep))
        paths = shared + paths
    os.environ['PATH'] = os.pathsep.join(dict.fromkeys(path for path in paths if path))


def executable(package: Package) -> str | None:
    found = shutil.which(package.command) if package.command else None
    if found and package.exclude and package.exclude.lower() in found.replace('\\', '/').lower():
        found = None
    if not found and os.name == 'nt':
        for pattern in package.search:
            matches = sorted(glob.glob(os.path.expandvars(pattern)), reverse=True)
            if matches:
                found = str(matches[0])
                break
    if found:
        directory = str(Path(found).parent)
        os.environ['PATH'] = directory + os.pathsep + os.environ.get('PATH', '')
    return found


def windows_registered(package: Package) -> bool:
    if package.npm:
        prefix = Path(os.environ['ProgramFiles']) / 'npm'
        with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE,
                            r'SYSTEM\CurrentControlSet\Control\Session Manager\Environment') as key:
            paths = os.path.expandvars(winreg.QueryValueEx(key, 'Path')[0]).lower().split(';')
        return ((prefix / 'node_modules' / package.npm / 'package.json').is_file()
                and (prefix / (package.command + '.cmd')).is_file()
                and str(prefix).lower() in paths)
    if package.provisioned:
        # AppX's installed-user inventory does not describe provisioning for new accounts.
        key = r'SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\InboxApplications'
        with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, key) as handle:
            names = [winreg.EnumKey(handle, index) for index in range(winreg.QueryInfoKey(handle)[0])]
        return any(name.startswith(package.provisioned + '_') for name in names)
    result = subprocess.run(['winget', 'list', '--id', package.winget, '--exact',
                             '--scope', package.scope, '--source', 'winget',
                             '--accept-source-agreements', '--disable-interactivity'],
                            capture_output=True, text=True)
    if result.returncode & 0xffffffff == 0x8a150014:  # NO_APPLICATIONS_FOUND
        return False
    if result.returncode:
        raise ValueError(f'WinGet inventory failed for {package.winget}: {result.stdout} {result.stderr}')
    return True


def installed(package: Package) -> bool:
    if (os.name == 'nt' and os.environ.get('RC_SETUP_REDIRECTED') != '1'
            and (package.winget or package.npm)):
        registered = windows_registered(package)
        if not registered or package.provisioned or package.npm:
            return registered
    if package.command:
        found = executable(package)
        if not found:
            return False
        if package.minimum:
            output = subprocess.check_output([found, '--version'], text=True)
            match = re.search(r'\d+(?:\.\d+)+', output)
            if not match:
                raise ValueError(f'Cannot read version of {package.command}')
            return tuple(map(int, match[0].split('.'))) >= package.minimum
        return True
    if sys.platform == 'linux' and package.apt:
        result = subprocess.run(['dpkg-query', '-W', '-f=${db:Status-Status}\n', *package.apt],
                                text=True, capture_output=True)
        return result.returncode == 0 and all(line == 'installed' for line in result.stdout.splitlines())
    return True


def privileged() -> list[str]:
    if os.geteuid() == 0:
        return []
    return ['sudo'] if sys.stdin.isatty() else ['sudo', '-n']


def apt(arguments: list[str]) -> None:
    subprocess.run([*privileged(), 'env', 'DEBIAN_FRONTEND=noninteractive', 'apt-get',
                    '-o', 'DPkg::Lock::Timeout=300', *arguments], check=True)


def install(packages: list[Package], *, scope: str = '', allow: bool = True) -> None:
    refresh_path()
    selected = [package for package in packages
                if (not scope or package.scope == scope)
                and ((package.winget or package.npm) if os.name == 'nt' else package.apt)]
    missing = [package for package in dict.fromkeys(selected)
               if not installed(package) or (allow and package.npm and os.environ.get('RC_SETUP_UPDATE') == '1')]
    if not missing:
        return
    if not allow or os.environ.get('RC_SETUP_REDIRECTED') == '1':
        names = ', '.join(package.command or '/'.join(package.apt) for package in missing)
        raise ValueError(f'Missing native requirements: {names}. Install them in the real account first.')
    if os.name == 'nt':
        windows_install(missing)
    elif sys.platform == 'linux':
        if not shutil.which('apt-get'):
            raise ValueError('Automatic Linux package installation requires apt-get')
        apt(['update'])
        apt(['install', '-y', *dict.fromkeys(name for package in missing for name in package.apt)])
    else:
        raise ValueError(f'Automatic package installation is unsupported on {sys.platform}')
    refresh_path()
    failed = [package.command or '/'.join(package.apt) for package in missing if not installed(package)]
    if failed:
        raise ValueError('Requirements still missing after installation: ' + ', '.join(failed))


def windows_install(packages: list[Package]) -> None:
    if not shutil.which('winget'):
        raise ValueError('Install Windows App Installer (WinGet), then rerun setup')
    helper = Path(__file__).with_name('windows.ps1')
    with tempfile.TemporaryDirectory(prefix='rc-packages-') as temporary:
        request = Path(temporary) / 'packages.json'
        request.write_text(json.dumps([asdict(package) for package in packages]), encoding='utf-8')
        subprocess.run(['powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass',
                        '-File', str(helper), '-Request', str(request)], check=True)


def persist_path(directory: Path) -> None:
    if os.name != 'nt' or os.environ.get('RC_SETUP_REDIRECTED') == '1':
        return
    with winreg.CreateKey(winreg.HKEY_CURRENT_USER, 'Environment') as key:
        try:
            value = winreg.QueryValueEx(key, 'Path')[0]
        except FileNotFoundError:
            value = ''
        if str(directory).lower() not in [os.path.expandvars(p).lower() for p in value.split(';')]:
            winreg.SetValueEx(key, 'Path', 0, winreg.REG_EXPAND_SZ, str(directory) + ';' + value)
            # Tell Explorer so new terminals inherit the installed tool path.
            ctypes.windll.user32.SendMessageTimeoutW(0xffff, 0x001A, 0, ctypes.c_wchar_p('Environment'), 2, 1000, None)
