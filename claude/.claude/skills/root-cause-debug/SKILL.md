---
name: root-cause-debug
description: >-
  Drive a reported failure from first sighting to a verified fix landed at the
  right layer, in one disciplined pass. Use when triaging a bug, regression, or
  crash — especially when a specific commit is suspected, or when the obvious fix
  site may not be the right one. Covers reproduce, isolate, root-cause, and choose
  the fix layer; hands off to pr-ready-self-review for finalization.
---

# Root-Cause Debug

The failure you see is the end of a chain, not its start. This skill takes you
from "it's broken" to "I have a verified fix at the correct layer" — without the
backtracking that comes from fixing the symptom, fixing the wrong layer, or
concluding from a run you never actually reproduced.

Apply `investigate-dont-assert` throughout: cite `file:line`, label
observed/inferred/unknown, back claims with minimal cases.

Work the phases in order. The early phases are not optional warm-up — skipping
reproduction or layer-choice is what causes the wasted loops this skill exists to
prevent.

## 1 — Freeze the experiment
Before touching anything, pin the variables: exact commit/SHA, input, flags,
build directory, and the metric that defines "broken." If any of these later
changes, the results are no longer the same run and cannot be compared.

## 2 — Reproduce on the exact failing commit, with a baseline
Reproduce the failure deterministically *on the named commit*. Then establish the
other side of the baseline: confirm it passes on the parent commit (or with the
suspected change reverted). Only once you have **fails-here / passes-there** is
the change proven causal and triage allowed to begin. A local pass is a clue, not
a ground truth — build the ground truth deliberately.

## 3 — Stay on the problematic commit; keep context minimal
Do the entire investigation and fix **in place**, on the failing commit. Do not
switch to main, rebase, cherry-pick, or pull in unrelated updates mid-flight —
each one changes the experiment and hides whether your fix is what mattered.
Defer all history surgery (rebasing/cherry-picking onto a PR base) to the very
end, after the fix is verified.

## 4 — Separate symptom from cause
The crash site is where the malformed state *blew up*, not where it was *created*.
Trace backward from the manifestation to the origin. Name the level of every
observation (which pass, which layer, which boundary) so you do not silently mix
them. Capture the actual intermediate state rather than paraphrasing what you
expect it to be.

## 5 — Prove the changed path is exercised
Before blaming the suspected change, prove the failing case actually runs through
it — with IR, logs, or a targeted counter, not intent. A plausible story that the
evidence does not place on the hot path is still a guess.

## 6 — Locate both the source and the site; enumerate fix layers
Name where the bad state originates (the source) and where it surfaces (the site)
as two distinct locations. List the candidate places a fix could go — at the
source, at an intermediate boundary, or at the site — instead of fixing the first
one you find.

## 7 — Compare against the reference
If a sibling backend, an upstream path, or an analogous component does *not* hit
this bug, find out exactly why. The mechanism that makes the other path immune
usually names both the real gap and the most robust place to close it.

## 8 — Choose the fix layer deliberately
"Closest to the root cause" is not automatically the right fix. Weigh each
candidate on **blast radius, regression risk, and robustness**:
- A deep source fix removes the cause but may be broad, generic, and risky —
  verify it does not regress unrelated cases.
- A boundary/defensive fix is narrower and more robust as a catch-all, even if it
  treats a symptom — it can be the right thing to land first.

Land the fix that is safe and robust now; file the deeper one as a tracked
follow-up if it is worth doing. Record why you chose this layer over the others.

## 9 — Verify end to end
Re-run the original reproduction from Phase 2 and confirm the failure is gone and
the baseline still passes. Check the siblings the fix touched for regressions. A
fix that is not re-validated against the exact starting repro is not done.

## 10 — Hand off
With the fix verified at the right layer, now do the deferred history work
(cherry-pick/rebase onto the PR base), then invoke `pr-ready-self-review` to turn
it into a submittable diff.

## Anti-patterns
- **Triaging before reproducing.** Explaining a failure you have only seen in a report.
- **Concluding from a passing run.** A nearby green result is not the failing path.
- **Fixing the crash site.** Patching where it blew up, leaving the origin intact.
- **"Most root-cause wins."** Reaching for the deepest fix without weighing blast radius — the trap that causes regressions and rework.
- **Rebasing mid-investigation.** Changing the base while still diagnosing, so you can no longer tell what fixed it.
- **No reference check.** Missing that a sibling path already shows the correct, robust fix.

## Checklist
- [ ] Experiment frozen: commit, input, flags, build, metric.
- [ ] Reproduced on the failing commit *and* shown to pass on parent/revert.
- [ ] Investigation done in place; no mid-flight rebase/cherry-pick/main-switch.
- [ ] Symptom and cause located as distinct points; levels named.
- [ ] Changed path proven exercised by IR/logs/counter.
- [ ] Fix layers enumerated; reference path's immunity understood.
- [ ] Fix layer chosen on blast radius/risk/robustness, with reason recorded.
- [ ] Re-verified against the original repro and baseline; siblings checked.
- [ ] History surgery deferred to the end; handed to pr-ready-self-review.
