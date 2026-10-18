---
name: handoff-work
description: >-
  Preserve active work so another agent, session, environment, or collaborator
  can continue without reconstructing it. Use when handing off a long task,
  switching harnesses or repositories, forking a side investigation, or when
  the user explicitly requests a handoff. Captures exact current state, evidence, commands,
  artifacts, decisions, constraints, dead ends, and the next discriminating
  action without duplicating durable project material.
---

# Handoff Work

A handoff is a continuation interface, not a transcript or retrospective. Include only what the receiver needs to resume correctly.

## Decide whether state must travel

- Continue in the current session when the work, directory, and reasoning context remain the same.
- Hand off when state must cross to another agent, session, environment, repository, or person.
- Compact in place when the task stays put but the working context has become noisy; do not create a handoff artifact merely to summarize.

## Build the handoff

1. **Name the continuation.** State the next session's goal, completion criteria, and immediate next action. Tailor the rest to that purpose.
2. **Pin current state.** Record the repository path, branch and tip SHA, relevant worktree state, build directory, run/job identifiers, and whether evidence came from the current tip or an older attempt.
3. **Carry authority and constraints.** Record the task contract, user decisions, scope boundaries, and whether commit, push, destructive actions, long builds, or external writes are authorized. Never infer authority from work already performed.
4. **Separate knowledge.** List established facts with their evidence, current hypotheses, and unknowns. Include exact reproducer/test commands, inputs, flags, meaningful output, and artifact paths.
5. **Link instead of copying.** Point to specs, plans, ledgers, ADRs, issues, commits, diffs, traces, and reports already stored durably. Summarize only the fact the receiver needs from each.
6. **Preserve the search frontier.** Record dead ends and why they failed, unresolved choices, risks, and the next experiment most likely to change the current belief.
7. **Redact.** Replace secrets, credentials, private identity data, and sensitive payloads with `<REDACTED>`. Refer to the secure source rather than copying protected values.
8. **Transport uncommitted work when needed.** Record the staged, unstaged, and untracked manifest. If the receiver cannot access the same working tree, ask where the changes may be stored, then package the selected tracked changes as a binary-safe patch and selected untracked files as an archive. Inspect the package for sensitive or unrelated content, record a checksum and restore instructions, and never commit merely to move state.
9. **Save deliberately.** Use a user-specified location. Otherwise use the platform temporary directory for a short-lived same-machine transfer; use a durable project location only when the user asks to retain the handoff. Report the exact path and its expected lifetime.

## Template

```markdown
# <task> handoff

## Continuation goal
Goal: ...
Done when: ...
Next action: ...

## Current state
- Repository / branch / tip:
- Worktree / build / run:
- Staged / unstaged / untracked manifest:
- Evidence freshness:

## Contract and authority
- In scope / out of scope:
- Constraints:
- Git / external-action authority:

## Established facts
- <fact> — <source, command, or artifact>

## Hypotheses and unknowns
- Supported / refuted / open:

## Reproduction and verification
- Command:
- Input and flags:
- Result:

## Durable artifacts
- <path or URL> — <why it matters>

## Transfer package (when the working tree is not shared)
- Patch / archive / checksum / restore instructions:

## Dead ends, risks, and remaining work
- ...

## Suggested skills
- `$<skill>` — <when to use it>
```

## Completion check

- [ ] The receiver can run the next action without asking what state or command was used.
- [ ] Claims link to evidence; hypotheses and unknowns are labeled.
- [ ] Existing artifacts are referenced, not recopied.
- [ ] Uncommitted work is either reachable in place or packaged for the receiver.
- [ ] Authority, sensitive-data handling, and artifact lifetime are explicit.
