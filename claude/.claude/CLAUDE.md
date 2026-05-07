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

## Communication Style

- Be direct. Light debate on technical matters is encouraged.
- Answer "why" before "what" — address root causes before proposing implementations.
- Don't claim work is "production ready" without justification.
- Don't initiate long build time activities without confirmation.

## Build & Test

- Builds typically happen in out-of-tree build directories.
- Multiple build configurations are often maintained simultaneously.
- Check `compile_commands.json` symlink to find the right build directory.
- Run specific tests after changes, not the full test suite.

## Design Documentation

- Always include an "Alternatives Considered" section in design docs.
- Focus on major architectural alternatives, not nit-picky differences.
