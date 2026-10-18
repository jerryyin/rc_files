"""Paths and process environment shared by application setup."""

from __future__ import annotations

from dataclasses import dataclass
import os
from pathlib import Path
import ssl
import subprocess


@dataclass(frozen=True)
class Context:
    repo: Path
    home: Path
    platform: str
    update: bool = False

    def environment(self) -> dict[str, str]:
        environment = dict(os.environ, HOME=str(self.home))
        if self.home != Path.home().resolve():
            environment.update(XDG_CONFIG_HOME=str(self.home / '.config'),
                               XDG_CACHE_HOME=str(self.home / '.cache'),
                               XDG_DATA_HOME=str(self.home / '.local/share'))
        if self.platform == 'windows':
            environment['USERPROFILE'] = str(self.home)
            if self.home != Path.home().resolve():
                environment.update(APPDATA=str(self.home / 'AppData/Roaming'),
                                   LOCALAPPDATA=str(self.home / 'AppData/Local'))
        environment.update(GIT_CONFIG_GLOBAL=os.devnull, GIT_TERMINAL_PROMPT='0',
                           RC_SETUP='1', RC_SETUP_UPDATE=str(int(self.update)))
        if not environment.get('NODE_EXTRA_CA_CERTS'):
            bundle = ssl.get_default_verify_paths().cafile
            if bundle:
                environment['NODE_EXTRA_CA_CERTS'] = bundle
        return environment

    def run(self, command: list[str], *, cwd: Path | None = None,
            environment: dict[str, str] | None = None) -> None:
        subprocess.run(command, cwd=cwd, env=environment or self.environment(), check=True)
