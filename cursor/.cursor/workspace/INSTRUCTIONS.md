# AI development workspace

This optional workspace holds cross-project notes, task records and review helpers. It is adapted from [stellaraccident/claude-rocm-workspace](https://github.com/stellaraccident/claude-rocm-workspace). It does not install personal rules into projects.

## Instructions and ownership

Shared personal guidance is authored in `rc_files/agents/.agents/AGENTS.md` and installed at `~/.agents/AGENTS.md`. Read it alongside the current project's native `AGENTS.md`. Conditional rules live in `~/.agents/rules/`; select them using their `Applies when:` lines and the actual project contents. The same selection instructions apply in Claude, Codex and Cursor, with no personal glob translations or per-project rule mirrors.

Cursor's global User Rule should direct it to read `~/.agents/AGENTS.md`; see `rc_files/.setup/agents-plan.md` for the exact entrypoint and its verification limits. Personal skills are discovered from `~/.agents/skills/`. Use their linked source directories when adding helpers. New personal rules or skills belong in the resolved Git source before deployment; project-specific guidance belongs in that project's `AGENTS.md`.

This workspace is available through direct configuration links at `~/.cursor/workspace/`. Edit `directory-map.md` for actual paths on the current execution host. Shell helpers below require Bash on Linux, WSL or another suitable host; they are not native PowerShell commands.

## Tasks

1. Copy `tasks/active/example-task.md` to a task-specific file when persistent task notes are useful.
2. Record the goal, relevant paths, decisions and evidence; add the task to `ACTIVE-TASKS.md`.
3. When finished, move its record to `tasks/completed/` and update the active index.

Task records describe work; they do not grant permission to commit, push or perform unrelated operations.

## Review helpers

- `python ~/.cursor/workspace/scripts/review.py comments <repo>` finds inline review comments.
- `python ~/.cursor/workspace/scripts/review.py stack <repo>` shows the commit stack; inspect the helper's options for a different base branch.
- `python ~/.cursor/workspace/scripts/review.py changed <repo>` shows changed files.
- `scripts/sync-status.sh` checks the repositories configured in that helper.
- `scripts/nuke-vscode.sh` is a Linux remote-server recovery helper; inspect its targets before use.

`RVW:` asks for discussion before a fix; `RVWY:` authorizes the requested fix. After addressing feedback, present the diff for review. Git actions follow the shared personal policy and the current user request; processing comments does not authorize a commit or push.
