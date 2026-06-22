---
name: pr-ready-self-review
description: >-
  Turn a working-but-rough change into a PR-ready diff in one pass via
  systematic self-review. Use after a solution works but before opening a PR, or
  when the user asks to finalize, clean up, polish, harden, or self-review a diff.
---

# PR-Ready Self-Review

A change that passes tests is not done. In one pass, reshape it into the diff you
would actually submit: small, clear, and fully justified.

Work the phases in order: 1–2 build understanding, 3–5 reshape the code, 6 fixes
comments, 7 presents. Re-run build/tests after any code-changing phase.

Throughout: apply `investigate-dont-assert` (ground every claim in the code);
**prefer clarity over cleverness**; **the default for any line you added is to
remove it unless it earns its place.**

## 1 — Intent & context
Understand the original before touching it. State the one problem solved, how the
original behaved and why it "worked," and the exact corner case the change
addresses. Most later decisions fall out of this.

## 2 — Examples
Back every non-trivial decision with a concrete example from the real code: the
input that triggers the new behavior, plus one case it accepts and one it
rejects (see `investigate-dont-assert`).

## 3 — Minimize the diff
- Fix the root cause; don't add cost (build/runtime/scope) to work around it.
- Revert anything not required for the fix, including your own incidental edits.
  If something can't cleanly adopt a change, leave it closest to the original.
- Delete dead or contradictory code. A guard for a state that cannot occur isn't
  "defensive" — it's noise (and is dangerous if it silently passes a bad input).
  Confirm unreachability with Phase 1 evidence before removing.

## 4 — Consolidate (separation of concerns)
- Audit duplication across all sibling call sites, not just the line you added.
  When your code joins several near-identical sites, lift the *entire* shared
  part into one helper — including pre-existing duplication — rather than stopping
  at your new check. This is the one allowed exception to Phase 3.
- A shared helper holds only what is common to every caller; caller-specific
  decisions stay in the caller. A parameter meaningful to only one caller is a
  smell — keep that special case with its owner.
- Collapse a helper that has one caller and is self-explanatory.

## 5 — Tests
- Cover at the cheapest layer that proves it (unit/IR over end-to-end). Drop a
  costly test a cheaper one already covers, and reuse existing positive coverage.
- Keep duplicated cases only when each exercises an independent code path.
- Make negative coverage representative: hit the distinct branches with varied
  cases, not one narrow case repeated.

## 6 — Comments
Brief intent above a unit, in the file's style — what it is, not how it works. No
narration of obvious code. Add a short "why" only where a corner case or
non-obvious decision needs justifying.

## 7 — Present
1. **Description** — problem, original behavior/bug, fix, any trade-off.
2. **Walkthrough** — intent, original logic, corner cases, each with an example.
3. **Diff** — final changes grouped logically, each non-obvious choice justified
   in a line.

## Checklist
- [ ] Every changed line necessary; incidental scope reverted.
- [ ] Root cause fixed, not worked around.
- [ ] No unreachable guards; claims backed by file:line.
- [ ] Duplication lifted once; no single-caller flags; special cases with owner.
- [ ] Tests: cheapest layer, no redundant layer, representative coverage.
- [ ] Comments: brief intent + targeted why.
- [ ] Build + tests pass.
