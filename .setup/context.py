"""Paths and process environment shared by application setup."""

from __future__ import annotations

from dataclasses import dataclass
import json
import os
from pathlib import Path
import shutil
import ssl
import subprocess
import urllib.request


@dataclass(frozen=True)
class Context:
    repo: Path
    home: Path
    backup: Path
    platform: str
    update: bool = False

    def environment(self) -> dict[str, str]:
        environment = dict(os.environ, HOME=str(self.home))
        if self.platform == 'windows':
            environment['USERPROFILE'] = str(self.home)
        environment.update(GIT_CONFIG_GLOBAL=os.devnull, GIT_TERMINAL_PROMPT='0')
        if not environment.get('NODE_EXTRA_CA_CERTS'):
            bundle = ssl.get_default_verify_paths().cafile
            if bundle:
                environment['NODE_EXTRA_CA_CERTS'] = bundle
        return environment

    def save(self, path: Path, text: str) -> None:
        if path.exists() and path.read_text(encoding='utf-8-sig') == text:
            return
        if path.exists():
            destination = self.backup / path.relative_to(self.home)
            destination.parent.mkdir(parents=True, exist_ok=True)
            if destination.exists():
                raise FileExistsError(f'Backup already exists: {destination}')
            shutil.copy2(path, destination)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding='utf-8', newline='\n')

    def save_json(self, path: Path, value: object) -> None:
        if path.exists() and json.loads(path.read_text(encoding='utf-8-sig')) == value:
            return
        self.save(path, json.dumps(value, indent=2) + '\n')

    def download(self, url: str, path: Path) -> None:
        with urllib.request.urlopen(url, timeout=60) as response:
            self.save(path, response.read().decode('utf-8'))

    def run(self, command: list[str], *, cwd: Path | None = None,
            environment: dict[str, str] | None = None) -> None:
        subprocess.run(command, cwd=cwd, env=environment or self.environment(), check=True)
