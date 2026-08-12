---
name: pr-ready-self-review
description: >-
  Turn a working change into a focused, reviewable diff by checking it
  independently against intent/specification and repository standards. Use
  after a solution works but before opening a PR, or when asked to finalize,
  clean up, harden, polish, or self-review a branch or working-tree change.
  Pins the exact tip and comparison base, minimizes scope, audits test quality,
  and runs targeted verification without committing or pushing implicitly.
---

# PR-Ready Self-Review

A passing change is not finished until the diff is necessary, understandable, and faithful to its intent.

Apply `investigate-dont-assert`: ground findings in the actual diff, code, tests, and project guidance. Preserve unrelated user changes.

Establish authority before proceeding. A request to review or report is read-only: inspect and report findings without editing. A request to clean up, finalize, harden, or polish authorizes in-scope edits, followed by another review pass.

## 1. Pin the review object

Record the current branch, tip SHA, `git status --short`, and fixed comparison point. Resolve the base and inspect its merge-base diff (`<base>...HEAD`), staged and unstaged diffs, and the full contents of in-scope untracked files. Fail early on a bad ref or unexpectedly empty review object.

Identify the originating issue, spec, task contract, or conversation. Find repository standards in applicable `AGENTS.md`, `CLAUDE.md`, rules, contributing docs, and neighboring code. State when no written spec exists.

## 2. Review two independent axes

Keep findings separate until both passes are complete:

- **Intent:** missing or partial requirements, behavior that was not requested, and implementation that appears to satisfy the words but not the intended behavior.
- **Standards:** correctness, project conventions, abstraction boundaries, maintainability, diagnostics, performance/compatibility/security risk when relevant, and test quality.

Repository-specific standards override generic preferences. Treat style or design smells as judgment calls unless a documented rule makes them hard requirements. Do not let success on one axis hide a failure on the other.

## 3. Understand before reshaping

State the one problem solved, the original behavior, the exact corner case, and why the new mechanism addresses it. Back non-trivial decisions with a concrete case from the real path: the triggering input plus a representative accepted and rejected case where useful.

## 4. Minimize the diff

When cleanup edits are authorized:

- Fix the root cause rather than adding cost or complexity around it.
- Remove incidental edits, speculative options, redundant guards, and dead or contradictory code.
- Preserve existing names, order, comments, logging, and style unless changing them is necessary.
- Keep generated changes separate and explain why they are present.

The default for each added line is removal until it earns its place.

## 5. Consolidate at the right seam

When cleanup edits are authorized, audit sibling call sites for the same logic. When duplication is real, move only the common policy behind one well-named interface; keep caller-specific decisions with their owners. Avoid parameters meaningful to one caller and helpers that merely forward a single call.

For a new abstraction, apply the deletion test: if removing it only removes indirection, it is too shallow; if its policy would spill across callers, it earns its seam.

## 6. Audit tests and comments

- Cover behavior at the cheapest faithful seam; use a unit/pass/IR test instead of end-to-end coverage when it proves the same contract.
- Verify the test would fail on the bug or missing behavior and that expected results come from an independent oracle.
- Reuse existing positive coverage; add representative negative cases for distinct branches without duplicating layers.
- Keep comments to brief intent and non-obvious rationale. Remove narration of visible code.

## 7. Verify and present

Run the narrow targeted checks after each code-changing cleanup. Run broader validation only in proportion to risk and user authorization; do not start a long build silently.

Present:

1. Current branch/tip, comparison base, and evidence freshness.
2. Intent findings and standards findings, kept distinct and ordered by severity.
3. Final problem/fix/trade-off summary and targeted test results.
4. Remaining risks, untested axes, and any deliberately deferred work.

## Completion check

- [ ] Review base, tip, tracked and untracked scope, and originating intent are explicit.
- [ ] Intent and standards were reviewed independently.
- [ ] Review-only requests produced findings without file edits.
- [ ] Every changed line is necessary; unrelated user work is untouched.
- [ ] Abstractions reduce policy duplication rather than add forwarding layers.
- [ ] Tests use faithful seams and independent expected results.
- [ ] Targeted validation passes; broader checks are authorized and proportionate.
- [ ] No commit or push occurred without current-turn authorization.
