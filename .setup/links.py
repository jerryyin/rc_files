"""Deploy tracked package trees as direct links, without saved deployment state."""

from __future__ import annotations

import argparse
import ctypes
from dataclasses import dataclass
import filecmp
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import uuid

from context import account_home

PLATFORMS = {".linux", ".windows", ".darwin"}
CSIDL_PERSONAL = 5
CSIDL_FLAG_DONT_VERIFY = 0x4000


@dataclass(frozen=True)
class Link:
    source: Path
    target: Path
    directory: bool = False


def absolute(path: Path) -> Path:
    return Path(os.path.abspath(path))


def is_link(path: Path) -> bool:
    if path.is_symlink():
        return True
    if os.name == "nt":
        try:
            tag = path.lstat().st_reparse_tag
        except (FileNotFoundError, NotADirectoryError):
            return False
        return tag == stat.IO_REPARSE_TAG_MOUNT_POINT
    return False


def matches(link: Link) -> bool:
    return link.source.exists() and is_link(link.target) and link.target.resolve() == link.source.resolve()


def tracked_files(repo: Path) -> dict[str, str]:
    output = subprocess.check_output(
        ["git", "-C", str(repo), "ls-files", "--stage", "-z"]
    ).decode("utf-8", "surrogateescape")
    result: dict[str, str] = {}
    for record in output.split("\0"):
        if not record:
            continue
        header, name = record.split("\t", 1)
        mode, _, stage = header.split()
        if stage != "0":
            raise ValueError(f"Resolve the Git conflict before deploying: {name}")
        if mode == "160000":
            raise ValueError(f"Submodule deployment is not supported: {name}")
        result[name] = mode
    return result


def resolve_source(path: Path, repo: Path, tracked: dict[str, str]) -> Path:
    # Git for Windows can check out a repository symlink as a text file.
    for _ in range(40):
        path = absolute(path)
        relative = path.relative_to(repo)
        prefix = repo
        for index, part in enumerate(relative.parts):
            prefix /= part
            name = prefix.relative_to(repo).as_posix()
            if tracked.get(name) == "120000":
                destination = os.readlink(prefix) if prefix.is_symlink() else prefix.read_text()
                path = prefix.parent / destination / Path(*relative.parts[index + 1:])
                break
        else:
            resolved = path.resolve(strict=True)
            resolved.relative_to(repo)
            return resolved
    raise ValueError(f"Repository symlink loop: {path}")


def destination(parts: tuple[str, ...], roots: dict[str, Path]) -> Path:
    root = roots["HOME"]
    if parts[0].startswith("@"):
        names = [("/".join((parts[0][1:],) + parts[1:index]), index)
                 for index in range(len(parts), 0, -1)]
        match = next(((name, index) for name, index in names if name in roots), None)
        if match is None:
            name = parts[0][1:]
            raise ValueError(f"Destination root @{name} is unavailable; supply --root {name}=PATH")
        name, count = match
        root, parts = roots[name], parts[count:]
    if not parts or any(part in (".", "..") for part in parts):
        raise ValueError(f"Invalid destination: {parts}")
    return root.joinpath(*parts)


def directory_children(source: Path, repo: Path, tracked: dict[str, str]) -> list[Path]:
    prefix = source.relative_to(repo).as_posix() + "/"
    names = {name[len(prefix):].split("/", 1)[0] for name in tracked if name.startswith(prefix)}
    return [source / name for name in sorted(names)]


def package_names(tracked: dict[str, str], packages: list[str]) -> list[str]:
    available = {name.split("/", 1)[0] for name in tracked
                 if "/" in name and not name.startswith(".")}
    if set(packages) - available:
        raise ValueError(f"Unknown packages: {', '.join(sorted(set(packages) - available))}")
    return sorted(set(packages) if packages else available)


def discover(repo: Path, platform: str, roots: dict[str, Path], packages: list[str]) -> list[Link]:
    repo = repo.resolve(strict=True)
    tracked = tracked_files(repo)
    selected: dict[str, tuple[int, Link]] = {}
    for package in package_names(tracked, packages):
        for name in sorted(tracked):
            if not name.startswith(package + "/"):
                continue
            parts = Path(name).parts[1:]
            priority = int(parts[0] in PLATFORMS)
            if priority:
                if parts[0] != "." + platform:
                    continue
                parts = parts[1:]
            if not parts or parts[0] in ('.setup', 'README.md'):
                continue
            marker = next((index for index, part in enumerate(parts) if part.endswith('.links')), None)
            if marker is not None and marker < len(parts) - 1:
                child_parts = parts[:marker] + (parts[marker][:-len('.links')], parts[marker + 1])
                depth = len(parts) - marker - 2
                child = (repo / name).parents[depth - 1] if depth else repo / name
                source = resolve_source(child, repo, tracked)
                links = [Link(source, destination(child_parts, roots), source.is_dir())]
            elif marker is not None:
                source = resolve_source(repo / name, repo, tracked)
                if not source.is_dir():
                    raise ValueError(f"A .links source must be a directory: {name}")
                target = destination(parts[:-1] + (parts[-1][:-len('.links')],), roots)
                links = [Link(child, target / child.name, child.is_dir())
                         for child in directory_children(source, repo, tracked)]
            else:
                source = resolve_source(repo / name, repo, tracked)
                target = destination(parts, roots)
                links = [Link(source, target, source.is_dir())]
            for link in links:
                key = str(link.target).casefold() if platform == "windows" else str(link.target)
                previous = selected.get(key)
                if previous and previous[0] == priority and previous[1].source != link.source:
                    raise ValueError(f"Two package files target {link.target}: {previous[1].source}, {link.source}")
                if not previous or previous[0] <= priority:
                    selected[key] = (priority, link)
    result = sorted((entry[1] for entry in selected.values()), key=lambda link: str(link.target))
    targets = {link.target for link in result}
    for link in result:
        if any(parent in targets for parent in link.target.parents):
            raise ValueError(f"Overlapping file/directory destinations: {link.target}")
        if link.target == repo or repo in link.target.parents:
            raise ValueError(f"Destination is inside the source repository: {link.target}")
    return result


def identical(source: Path, target: Path) -> bool:
    if source.is_file() and target.is_file():
        return filecmp.cmp(source, target, shallow=False)
    if source.is_dir() and target.is_dir():
        left = {entry.name for entry in source.iterdir()}
        right = {entry.name for entry in target.iterdir()}
        return left == right and all(
            not is_link(target / name) and identical(source / name, target / name)
            for name in left
        )
    return False


def owned_broken_link(path: Path, repo: Path | None) -> bool:
    if repo is None or not is_link(path) or path.exists():
        return False
    target = Path(os.readlink(path).removeprefix("\\\\?\\"))
    if not target.is_absolute():
        target = path.parent / target
    return target.resolve().is_relative_to(repo.resolve())


def owned_source_alias(link: Link, repo: Path | None) -> bool:
    if repo is None or not source_owned(link.target, repo):
        return False
    original = Path(os.readlink(link.target).removeprefix("\\\\?\\"))
    if not original.is_absolute():
        original = link.target.parent / original
    original = absolute(original)
    return original.is_relative_to(repo) and resolve_source(original, repo, tracked_files(repo)) == link.source


def problem(link: Link, replace: bool = False, backup: Path | None = None,
            repo: Path | None = None) -> str | None:
    if not link.source.exists():
        return f"Source is missing: {link.source}"
    if matches(link):
        return None
    for parent in link.target.parents:
        if is_link(parent):
            return f"Destination parent is a link; unfold it before deployment: {parent}"
        if parent.exists() and not parent.is_dir():
            return f"Destination parent is a file: {parent}"
    if os.path.lexists(link.target):
        if (not replace and not owned_broken_link(link.target, repo) and not owned_source_alias(link, repo)
                and (is_link(link.target) or not identical(link.source, link.target))):
            return f"Configuration conflict: {link.target} differs from {link.source}; nothing replaced"
        if link.target.is_dir() and not is_link(link.target) and not backup:
            return f"A backup directory is required to replace {link.target}"
    return None


def install(link: Link, backup: Path | None) -> None:
    if matches(link):
        return
    link.target.parent.mkdir(parents=True, exist_ok=True)
    temporary = link.target.with_name(link.target.name + ".link-" + uuid.uuid4().hex)
    try:
        os.symlink(link.source, temporary, target_is_directory=link.directory)
        if os.path.lexists(link.target):
            if backup:
                backup.mkdir(parents=True, exist_ok=True)
                saved = backup / (link.target.name + "." + uuid.uuid4().hex)
                shutil.move(str(link.target), str(saved))
            elif link.target.is_dir() and not is_link(link.target):
                raise ValueError(f"A backup directory is required to replace {link.target}")
            elif is_link(link.target):
                if os.name == "nt" and stat.S_ISDIR(link.target.lstat().st_mode):
                    os.rmdir(link.target)
                else:
                    link.target.unlink()
        os.replace(temporary, link.target)
        if not matches(link):
            raise OSError(f"Link validation failed: {link.target}")
    finally:
        if temporary.is_symlink():
            temporary.unlink()


def source_owned(path: Path, repo: Path) -> bool:
    return is_link(path) and path.resolve().is_relative_to(repo)


def preserve_link(path: Path, backup: Path, home: Path) -> None:
    relative = path.relative_to(home) if path.is_relative_to(home) else Path(path.name)
    saved = backup / 'links' / relative
    if os.path.lexists(saved):
        saved = saved.with_name(saved.name + '.' + uuid.uuid4().hex)
    saved.parent.mkdir(parents=True, exist_ok=True)
    path.rename(saved)


def unfold(source: Path, target: Path, repo: Path, tracked: dict[str, str]) -> None:
    target.mkdir()
    if not source.exists():
        return
    for entry in source.iterdir():
        name = entry.relative_to(repo).as_posix()
        child = target / entry.name
        if entry.is_dir() and not is_link(entry) and any(key.startswith(name + '/') for key in tracked):
            unfold(entry, child, repo, tracked)
        elif name in tracked:
            actual = resolve_source(entry, repo, tracked)
            os.symlink(actual, child, target_is_directory=actual.is_dir())
        else:
            shutil.move(str(entry), str(child))


def migrate_parents(links: list[Link], repo: Path, home: Path, backup: Path) -> None:
    parents = {parent for link in links for parent in link.target.parents if parent != repo}
    tracked = tracked_files(repo)
    for parent in sorted(parents, key=lambda path: len(path.parts)):
        if not source_owned(parent, repo):
            continue
        source = parent.resolve()
        temporary = parent.with_name(parent.name + '.unfold-' + uuid.uuid4().hex)
        unfold(source, temporary, repo, tracked)
        preserve_link(parent, backup, home)
        os.replace(temporary, parent)


def prune_links(links: list[Link], repo: Path, home: Path, backup: Path,
                other_platforms: list[Link] | None = None) -> None:
    wanted = {link.target for link in links}
    active_parents = {parent for link in links for parent in link.target.parents}
    parents = {parent for link in links + (other_platforms or [])
               for parent in link.target.parents if parent.is_relative_to(home)}
    # Retired configuration directories can outlive every file in their old plan.
    for parent in tuple(parents - {home}):
        if not parent.is_dir() or is_link(parent):
            continue
        for child in parent.iterdir():
            if child in parents or not child.is_dir() or is_link(child) or child.is_relative_to(repo):
                continue
            try:
                entries = list(child.iterdir())
            except (PermissionError, FileNotFoundError):
                continue
            if any(source_owned(entry, repo) for entry in entries):
                parents.add(child)
    for parent in sorted(parents, key=str):
        if not parent.is_dir() or is_link(parent):
            continue
        for child in list(parent.iterdir()):
            if (child not in wanted and child not in parents and not child.is_relative_to(repo)
                    and source_owned(child, repo)):
                preserve_link(child, backup, home)
                directory = child.parent
                while directory != home and directory not in active_parents and not any(directory.iterdir()):
                    directory.rmdir()
                    directory = directory.parent


def run(args: argparse.Namespace) -> int:
    roots = {"HOME": absolute(args.home)}
    native_home = roots["HOME"] == account_home()
    for name, suffix in (("APPDATA", "Roaming"), ("LOCALAPPDATA", "Local")):
        roots[name] = (absolute(Path(os.environ[name]))
                       if os.name == "nt" and native_home and os.environ.get(name)
                       else roots["HOME"] / "AppData" / suffix)
    roots["DOCUMENTS"] = roots["HOME"] / "Documents"
    if (os.name == "nt" and native_home and not args.source
            and not any(entry.startswith("DOCUMENTS=") for entry in args.root)):
        buffer = ctypes.create_unicode_buffer(32768)
        if ctypes.windll.shell32.SHGetFolderPathW(None, CSIDL_PERSONAL | CSIDL_FLAG_DONT_VERIFY, None, 0, buffer) != 0:
            raise OSError("Cannot locate the Windows Documents folder")
        roots["DOCUMENTS"] = Path(buffer.value)
    for entry in args.root:
        name, path = entry.split("=", 1)
        roots[name] = absolute(Path(path))
    if args.replace_existing and not args.backup:
        raise ValueError("--replace-existing requires --backup")
    if args.action == "link" or args.source or args.target:
        if not args.source or not args.target:
            raise ValueError("link requires --source and --target")
        source = args.source.resolve(strict=args.action != "check")
        links = [Link(source, absolute(args.target), source.is_dir())]
    else:
        links = discover(args.repo.resolve(strict=True), args.platform, roots, args.package)
    if args.action == 'migrate':
        if not args.backup or args.package:
            raise ValueError('migrate requires --backup and the complete package tree')
        other_platforms = [link for platform in sorted(PLATFORMS - {'.' + args.platform})
                           for link in discover(args.repo, platform[1:], roots, [])]
        migrate_parents(links, args.repo.resolve(), roots['HOME'], args.backup)
    issues: list[str] = []
    for link in links:
        if args.action == "check":
            if not matches(link):
                issues.append(f"Link missing or detached: {link.target} -> {link.source}")
        elif args.action != "plan":
            issue = problem(link, args.replace_existing, args.backup, args.repo)
            if issue:
                issues.append(issue)
    if args.json:
        print(json.dumps({"links": [{"source": str(link.source), "target": str(link.target),
                                      "directory": link.directory} for link in links], "problems": issues}))
    elif issues:
        print("\n".join(issues), file=sys.stderr)
    else:
        for link in links:
            status = "OK" if matches(link) else "LINK"
            print(f"{status} {link.target} -> {link.source}")
    if issues:
        return 1
    if args.action in ("apply", "migrate", "link"):
        for link in links:
            install(link, args.backup)
        if args.action == 'migrate':
            prune_links(links, args.repo.resolve(), roots['HOME'], args.backup, other_platforms)
    return 0
