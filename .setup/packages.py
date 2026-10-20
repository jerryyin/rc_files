"""Discover package-owned requirements and order their setup entries."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import runpy

import links
from system import Package


@dataclass
class Selection:
    names: list[str]
    requirements: list[Package]


def discover(repo: Path, tracked: dict[str, str], selected: list[str], platform: str) -> Selection:
    repo = repo.resolve(strict=True)
    names: list[str] = []
    visiting: set[str] = set()
    requirements: list[Package] = []

    def visit(name: str) -> None:
        if name in visiting:
            raise ValueError(f'Circular package dependency: {name}')
        if name in names:
            return
        links.package_names(tracked, [name])
        visiting.add(name)
        path = f'{name}/.setup/requirements.py'
        entry = links.resolve_source(repo / path, repo, tracked) if path in tracked else None
        choices = runpy.run_path(str(entry), init_globals={'PLATFORM': platform}) if entry else {}
        for dependency in choices.get('DEPENDENCIES', ()):
            visit(dependency)
        requirements.extend(choices.get('PACKAGES', ()))
        names.append(name)
        visiting.remove(name)

    for name in links.package_names(tracked, selected):
        visit(name)
    return Selection(names, list(dict.fromkeys(requirements)))
