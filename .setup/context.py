"""Process environment for package setup in the selected home."""

from __future__ import annotations

import ctypes
import os
from pathlib import Path

if os.name != 'nt':
    import pwd

CSIDL_PROFILE = 40

def account_home() -> Path:
    if os.name != 'nt':
        return Path(pwd.getpwuid(os.getuid()).pw_dir).resolve()
    buffer = ctypes.create_unicode_buffer(32768)
    if ctypes.windll.shell32.SHGetFolderPathW(None, CSIDL_PROFILE, None, 0, buffer) != 0:
        raise OSError('Cannot locate the Windows account profile')
    return Path(buffer.value).resolve()


def environment(home: Path, update: bool) -> dict[str, str]:
    result = dict(os.environ, HOME=str(home))
    redirected = home != account_home()
    if redirected:
        result.update(XDG_CONFIG_HOME=str(home / '.config'),
                      XDG_CACHE_HOME=str(home / '.cache'),
                      XDG_DATA_HOME=str(home / '.local/share'))
    if os.name == 'nt':
        result['USERPROFILE'] = str(home)
        if redirected:
            result.update(APPDATA=str(home / 'AppData/Roaming'),
                          LOCALAPPDATA=str(home / 'AppData/Local'))
    result.update(GIT_CONFIG_GLOBAL=os.devnull, GIT_TERMINAL_PROMPT='0',
                  RC_SETUP='1', RC_SETUP_UPDATE=str(int(update)),
                  RC_SETUP_REDIRECTED=str(int(redirected)))
    return result


def prepare(settings: dict[str, str]) -> None:
    if os.name == 'nt' and settings['RC_SETUP_REDIRECTED'] == '1':
        # PowerShell falls back to its working directory when AppData is absent.
        for name in ('APPDATA', 'LOCALAPPDATA'):
            Path(settings[name]).mkdir(parents=True, exist_ok=True)
