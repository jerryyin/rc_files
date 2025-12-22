#!/usr/bin/env python3
"""
review.py - Centralized review workflow script

Supports both local (direct code) and remote (file watcher) VSCode modes.
Used by AI assistants for code review workflow.

Commands:
    comments [path]             Collect RVW: comments as JSON
    stack [path] [branch]       Show commit stack since branch
"""

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path


def git(*args, cwd: Path | None = None) -> subprocess.CompletedProcess:
    """Run git command and return result."""
    result = subprocess.run(
        ["git", *args],
        capture_output=True,
        text=True,
        cwd=cwd,
    )
    return result


def cmd_comments(repo: Path) -> dict:
    """Find all RVW: and RVWY: comments in the repo."""
    # Use grep to find RVW/RVWY comments (RVWY = YOLO mode, fix without asking)
    result = subprocess.run(
        [
            "grep",
            "-rn",
            "-E",
            "RVWY?:",
            "--include=*.py",
            "--include=*.cpp",
            "--include=*.c",
            "--include=*.h",
            "--include=*.hpp",
            "--include=*.cmake",
            "--include=CMakeLists.txt",
            "--include=*.md",
            "--include=*.toml",
            "--include=*.yaml",
            "--include=*.yml",
            "--include=*.sh",
            "--include=*.js",
            "--include=*.ts",
            "--include=*.rs",
            "--include=*.go",
            ".",
        ],
        capture_output=True,
        text=True,
        cwd=repo,
    )

    comments = []
    for line in result.stdout.strip().split("\n"):
        if not line:
            continue
        # Parse: ./path/file.py:42:    // RVW: fix this
        match = re.match(r"^\.?/?([^:]+):(\d+):(.*)$", line)
        if match:
            filepath = match.group(1)
            lineno = int(match.group(2))
            content = match.group(3).strip()

            # Check for RVWY (yolo) vs RVW (discuss)
            rvwy_match = re.search(r"RVWY:\s*(.*)$", content)
            rvw_match = re.search(r"RVW:\s*(.*)$", content)

            if rvwy_match:
                comment_text = rvwy_match.group(1)
                yolo = True
            elif rvw_match:
                comment_text = rvw_match.group(1)
                yolo = False
            else:
                continue  # Not a real RVW comment

            comments.append({
                "file": str(repo / filepath),
                "relative_path": filepath,
                "line": lineno,
                "raw": content,
                "comment": comment_text,
                "yolo": yolo,
            })

    return {
        "repo": str(repo),
        "count": len(comments),
        "comments": comments,
    }


def cmd_stack(repo: Path, branch: str = "main") -> dict:
    """Show commit stack since branch."""
    # Get merge base
    merge_base_result = git("merge-base", "HEAD", branch, cwd=repo)
    if merge_base_result.returncode != 0:
        return {
            "status": "error",
            "error": f"Could not find merge base with {branch}",
            "repo": str(repo),
        }

    merge_base = merge_base_result.stdout.strip()

    # Get log
    log_result = git("log", "--oneline", f"{merge_base}..HEAD", cwd=repo)
    commits = [c for c in log_result.stdout.strip().split("\n") if c]

    # Get current branch
    branch_result = git("branch", "--show-current", cwd=repo)
    current_branch = branch_result.stdout.strip() if branch_result.returncode == 0 else "unknown"

    # Get stats
    stat_result = git("diff", "--stat", merge_base, cwd=repo)
    stats = stat_result.stdout.strip() if stat_result.returncode == 0 else ""

    return {
        "repo": str(repo),
        "branch": current_branch,
        "base": branch,
        "merge_base": merge_base[:8],
        "commits": commits,
        "count": len(commits),
        "stats": stats,
    }


def cmd_changed(repo: Path, base: str = "HEAD~1") -> dict:
    """Show files changed since base ref."""
    result = git("diff", "--name-only", base, cwd=repo)
    if result.returncode != 0:
        return {
            "status": "error",
            "error": result.stderr.strip(),
            "repo": str(repo),
        }

    files = [f for f in result.stdout.strip().split("\n") if f]
    return {
        "repo": str(repo),
        "base": base,
        "files": files,
        "count": len(files),
    }


def main():
    parser = argparse.ArgumentParser(
        description="Review workflow helper",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    # comments
    p_comments = subparsers.add_parser("comments", help="Find RVW: comments")
    p_comments.add_argument("path", nargs="?", default=".", help="Repository path")

    # stack
    p_stack = subparsers.add_parser("stack", help="Show commit stack")
    p_stack.add_argument("path", nargs="?", default=".", help="Repository path")
    p_stack.add_argument("branch", nargs="?", default="main", help="Base branch")

    # changed
    p_changed = subparsers.add_parser("changed", help="Show changed files")
    p_changed.add_argument("path", nargs="?", default=".", help="Repository path")
    p_changed.add_argument("base", nargs="?", default="HEAD~1", help="Base ref")

    args = parser.parse_args()

    try:
        repo = Path(args.path).resolve()

        if args.command == "comments":
            result = cmd_comments(repo)
        elif args.command == "stack":
            result = cmd_stack(repo, args.branch)
        elif args.command == "changed":
            result = cmd_changed(repo, args.base)
        else:
            parser.print_help()
            sys.exit(1)

        print(json.dumps(result, indent=2))

    except ValueError as e:
        print(json.dumps({"status": "error", "error": str(e)}), file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(json.dumps({"status": "error", "error": str(e)}), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()

