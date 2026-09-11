# User Preferences

## Git Workflow

- Never `git push` without explicit authorization
- Never amend commits without explicit authorization
- Stage changes and ask for reviews before committing
- Branch naming: `users/<username>/<short-description>`
- Use short form issue references (#NNNN) instead of full URLs

### Git Action Gate

Editing is not permission to commit or push. Only commit, amend, push,
force-push, stash, or reset when explicitly requested in the current user turn.
Before any git write, summarize the intended action and affected files.

## Complex Task Contract

For complex implementation, debugging, or benchmarking work, first establish the
task contract: goal, success criteria, files/systems in scope, constraints, and
whether commits or pushes are allowed. Update the contract when the user changes
direction.

## Current State First

For PR, CI, or debugging discussions, identify the exact current state before
interpreting results: current branch/tip SHA, relevant run or job, and whether
the data is from the current tip or an older attempt. If several pushes or runs
exist, name them separately instead of merging them into one narrative.

## Concrete First

- Show the thing, don't describe it: print the actual value, walk the real data flow with real names and `file:line`, quote the real output. A rule the reader still has to apply themselves is not the same as the applied result — give the result. Abstractions and summaries come after the example, never instead of it.
- Use the smallest instance where the point is visible; production-scale values usually hide it.

## Communication Style

- Be direct. Light debate on technical matters is encouraged.
- Answer "why" before "what" — address root causes before proposing implementations.
- Don't claim work is "production ready" without justification.
- Don't initiate long build time activities without confirmation.

## Comments

- Match comment and docstring density to the surrounding file; when there is no precedent, err sparse.

## Build & Test

- Builds typically happen in out-of-tree build directories.
- Multiple build configurations are often maintained simultaneously.
- Check `compile_commands.json` symlink to find the right build directory.
- Run specific tests after changes, not the full test suite.

## Contextual Rules

Additional guidance lives in `~/.claude/rules/`. Before relevant work, read and follow only the files whose topic, `description`, or `globs` frontmatter matches the task or current path.

## Design Documentation

- Always include an "Alternatives Considered" section in design docs.
- Focus on major architectural alternatives, not nit-picky differences.
