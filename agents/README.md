# Shared agent configuration

Personal instructions, conditional rules and skills have one authored source under `agents/.agents`. The Python setup deploys this collection on each execution host. Tool settings remain in their application packages; credentials, caches, sessions and application-managed skills remain local.

## Instructions and rules

`agents/.agents/AGENTS.md` owns shared personal preferences and the procedure for selecting conditional rules from `rules/`. Each rule states `Applies when:` so the same written selection procedure works across tools without translated glob metadata or a second rule inventory.

Deployment links the shared instruction file to these entry points:

- `~/.agents/AGENTS.md`: the neutral personal instruction location.
- `~/.codex/AGENTS.md`: the Codex global entry point.
- `~/.claude/CLAUDE.md`: the Claude global entry point.

Cursor's global User Rule is an account setting. Add this pointer through its settings UI:

```text
At the start of a session, read ~/.agents/AGENTS.md and follow its personal instructions alongside the project's instructions. If the file cannot be read, report its path and the access problem.
```

The pointer requests a file read; it does not deploy the file or establish that a fresh session has read it. Project-owned guidance belongs in the project's `AGENTS.md`. Preserve existing project `CLAUDE.md` files and their documented loading choices.

## Skills

Author personal skills in `agents/.agents/skills.links/<name>/`, with a `SKILL.md` and any supporting resources. Setup discovers tracked skill directories and links each one into both `~/.agents/skills/<name>` and `~/.claude/skills/<name>`. Cursor uses the shared skill root.

Per-skill directory links keep edits and new helper files attached to their Git source while leaving application-managed collections under their existing ownership. `AGENTS.md` does not replace skill discovery. A new sibling created directly in an installed skill root is not automatically part of this repository.

## Making changes

Resolve installed links before editing personal configuration. Put always-needed guidance in the shared `AGENTS.md`, conditional guidance in an existing applicable rule, and reusable procedures in skills. Keep project-specific instructions with their project.

Stage intended new content, then run `python3 .setup --config-only` from the repository root (`py -3 .setup --config-only` on Windows). No separate inventory needs updating. See [setup conventions](../.setup/README.md) for conflicts, backups and ignored authored files.

Claude settings are linked from their application package. Codex's tracked template initializes a missing local configuration; changing the template does not overwrite an existing local configuration. Record wanted application integrations in their tracked settings while leaving downloaded plugin code with the application.

## Checking an installation

`python3 .setup check --package agents` checks deployed link ownership. Separately inspect each tool's skill discovery and instruction loading in a fresh session. Confirm that relevant rules are read for a matching task and unrelated rule bodies stay unloaded. A filesystem check, discovery listing and actual task behavior establish different things.

Repeat deployment and loading checks in every intended WSL, remote, container or cloud environment. Local links and account-synced pointers do not establish that the referenced files exist on another host. Local Claude loading can be checked without a model response; actual conditional selection still needs a real session.
