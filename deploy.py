#!/usr/bin/env python3
"""Deploy tracked package trees as direct links, without saved deployment state."""

from __future__ import annotations

import argparse
import ctypes
from dataclasses import dataclass
import filecmp
import json
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import sys
import uuid


PLATFORMS = {".linux", ".windows", ".darwin"}
METADATA = {".stow-local-ignore", ".stow-global-ignore", ".deploy-ignore"}
DEFAULT_IGNORES = (r"(^|/)(README[^/]*|LICENSE[^/]*|COPYING)$", r"(~|\.sw[op])$")
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


def ignore_patterns(repo: Path, package: str) -> list[re.Pattern[str]]:
    patterns = list(DEFAULT_IGNORES)
    for path in (repo / package / ".stow-local-ignore", repo / package / ".deploy-ignore"):
        if path.is_file():
            patterns.extend(line.split("#", 1)[0].strip() for line in path.read_text().splitlines())
    return [re.compile(pattern) for pattern in patterns if pattern]


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


def discover(repo: Path, platform: str, roots: dict[str, Path], packages: list[str]) -> list[Link]:
    repo = repo.resolve(strict=True)
    tracked = tracked_files(repo)
    available = {name.split("/", 1)[0] for name in tracked if "/" in name}
    if set(packages) - available:
        raise ValueError(f"Unknown packages: {', '.join(sorted(set(packages) - available))}")
    selected: dict[str, tuple[int, Link]] = {}
    for package in sorted(available):
        if package.startswith(".") or (packages and package not in packages):
            continue
        patterns = ignore_patterns(repo, package)
        for name in sorted(tracked):
            if not name.startswith(package + "/"):
                continue
            parts = Path(name).parts[1:]
            priority = int(parts[0] in PLATFORMS)
            if priority:
                if parts[0] != "." + platform:
                    continue
                parts = parts[1:]
            if not parts or any(part in METADATA for part in parts):
                continue
            if any(pattern.search("/".join(parts)) for pattern in patterns):
                continue
            source = resolve_source(repo / name, repo, tracked)
            if parts[-1].endswith(".links"):
                if not source.is_dir():
                    raise ValueError(f"A .links source must be a directory: {name}")
                target = destination(parts[:-1] + (parts[-1][:-len('.links')],), roots)
                links = [Link(child, target / child.name, child.is_dir())
                         for child in directory_children(source, repo, tracked)]
            else:
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
        if not replace and not owned_broken_link(link.target, repo) and (is_link(link.target) or not identical(link.source, link.target)):
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
                if link.target.is_dir() and os.name == "nt":
                    os.rmdir(link.target)
                else:
                    link.target.unlink()
        os.replace(temporary, link.target)
        if not matches(link):
            raise OSError(f"Link validation failed: {link.target}")
    finally:
        if temporary.is_symlink():
            temporary.unlink()


def arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("plan", "apply", "check", "link"))
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parent)
    parser.add_argument("--home", type=Path, default=Path.home())
    parser.add_argument("--platform", choices=("linux", "windows", "darwin"),
                        default="windows" if os.name == "nt" else sys.platform)
    parser.add_argument("--root", action="append", default=[], metavar="NAME=PATH")
    parser.add_argument("--package", action="append", default=[])
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--backup", type=Path)
    parser.add_argument("--replace-existing", action="store_true")
    parser.add_argument("--source", type=Path)
    parser.add_argument("--target", type=Path)
    return parser.parse_args()


def main() -> int:
    args = arguments()
    roots = {"HOME": absolute(args.home)}
    native_home = roots["HOME"] == absolute(Path.home())
    for name, suffix in (("APPDATA", "Roaming"), ("LOCALAPPDATA", "Local")):
        if os.name == "nt":
            roots[name] = absolute(Path(os.environ[name])) if native_home and os.environ.get(name) else roots["HOME"] / "AppData" / suffix
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
    if args.action in ("apply", "link"):
        for link in links:
            install(link, args.backup)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f"deploy: {error}", file=sys.stderr)
        sys.exit(1)
