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
- **No jargon, in replies or in reasoning.** Write in plain words by default. This
  applies to internal reasoning too, not just the reply — reasoning that drifts into
  private shorthand produces replies that need translating afterwards.
- Project-internal shorthand — rule numbers, gate names, amendment letters, run ids,
  code names — is not self-explanatory. Say what the thing *is*, and attach the
  identifier only as a reference for looking it up later.
- Say the conclusion in ordinary language first. If a term is genuinely needed,
  define it once at first use.

## Comments

- Match comment and docstring density to the surrounding file; when there is no precedent, err sparse.
- A docstring states the contract: what the caller passes, what comes back, and what is not obvious from the signature. Mechanism and motivation belong in the PR description or in a comment at the line where the behaviour happens.

## Build & Test

- Builds typically happen in out-of-tree build directories.
- Multiple build configurations are often maintained simultaneously.
- Check `compile_commands.json` symlink to find the right build directory.
- Run specific tests after changes, not the full test suite.

## Contextual Rules

Additional personal guidance lives in `~/.agents/rules/`. Before substantive work, list the rule files and read their `Applies when:` lines. Read and follow the full rules whose conditions match the task or the actual project. Identify a project by its contents and instructions, so renamed checkouts and worktrees receive the same guidance. These are shared Markdown instructions; their selection does not depend on a tool's native glob loader. Task-specific rules and templates remain unloaded when their conditions do not match.

## Personal Configuration Ownership

- Resolve `~/.agents/AGENTS.md` to find the Git-owned personal configuration directory. Author new personal rules in its `rules/` directory and new skills in `skills.links/<name>/`; each skill has a `SKILL.md` with its own name, description, and supporting resources.
- Resolve installed file links before editing personal configuration and edit the Git source. A new sibling directory in an installed skills root is not automatically owned by the repository. Use the existing Python setup to deploy newly tracked content, and stage only intended authored files for review.
- Keep project instructions in the project's own `AGENTS.md`. Application-managed skills, plugin code, caches, credentials, and session state keep their application ownership. Record wanted integration choices in the application's tracked settings.

## Tools and Execution Hosts

- Check the tools available in the current session before following a tool-specific step. Use scheduling and delegation only when supported and authorized. If a required capability is absent, report the missing step rather than claim it was completed.
- Establish where a command must run: native Windows, WSL, a container, or a remote host. Discover paths and prerequisites on that host. Linux hardware workflows may run remotely without being translated into PowerShell.
- A local installation does not establish remote or cloud availability. Deploy this collection in the actual execution environment and confirm its instruction and skill discovery there. Report a missing shared instruction file instead of silently assuming its content.

## Design Documentation

- Always include an "Alternatives Considered" section in design docs.
- Focus on major architectural alternatives, not nit-picky differences.
