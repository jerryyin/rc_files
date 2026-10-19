"""Process environment for package setup in the selected home."""

from __future__ import annotations

import os
from pathlib import Path


def environment(home: Path, update: bool) -> dict[str, str]:
    result = dict(os.environ, HOME=str(home))
    if home != Path.home().resolve():
        result.update(XDG_CONFIG_HOME=str(home / '.config'),
                      XDG_CACHE_HOME=str(home / '.cache'),
                      XDG_DATA_HOME=str(home / '.local/share'))
    if os.name == 'nt':
        result['USERPROFILE'] = str(home)
        if home != Path.home().resolve():
            result.update(APPDATA=str(home / 'AppData/Roaming'),
                          LOCALAPPDATA=str(home / 'AppData/Local'))
    result.update(GIT_CONFIG_GLOBAL=os.devnull, GIT_TERMINAL_PROMPT='0',
                  RC_SETUP='1', RC_SETUP_UPDATE=str(int(update)),
                  RC_SETUP_REDIRECTED=str(int(home != Path.home().resolve())))
    return result
