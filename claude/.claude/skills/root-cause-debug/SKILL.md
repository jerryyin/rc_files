---
name: root-cause-debug
description: >-
  Drive a bug, functional or performance regression, crash, slowdown, or
  incorrect result from exact current state
  to a verified cause and, when authorized, a fix at the right layer. Use for
  bounded debugging and triage, especially when a commit is suspected or the
  visible failure may be downstream of its origin. Builds a faithful feedback
  loop, isolates the cause, weighs fix layers, adds a real regression test, and
  hands the finished diff to pr-ready-self-review.
---

# Root-Cause Debug

The visible failure is the end of a chain. Trace it to where the bad state begins, then choose the safest layer that prevents recurrence.

Apply `investigate-dont-assert`: cite source, preserve raw artifacts, label observed/inferred/unknown, and redact secrets before showing commands, logs, traces, or captured requests.

## 1. Pin state, scope, and authority

Record the branch and tip SHA, relevant run/job, build directory, exact input and flags, environment/toolchain, and the metric that defines failure. Distinguish evidence from the current tip from older attempts.

Confirm whether the user asked for diagnosis only or also authorized implementation. Diagnosis does not imply permission to edit, commit, rebase, or perform other Git writes.

## 2. Build a feedback loop that detects this bug

Create one runnable command that you have observed catch the user's exact symptom. Prefer an existing focused test; otherwise use the narrowest faithful CLI invocation, differential run, captured-input replay, property/fuzz loop, or small harness.

Make the loop:

- **Red-capable:** asserts the reported symptom, not merely “did not crash.”
- **Stable:** deterministic, or with a measured and high enough reproduction rate for a flaky failure.
- **Tight:** as fast and isolated as the real system permits; cache setup and exclude unrelated work.
- **Repeatable:** pins the variables another agent needs to run it unattended.

If no faithful loop is possible, report what was tried and the concrete access, artifact, or instrumentation needed. Do not manufacture a cause from code reading alone.

## 3. Establish causality and shrink the case

Run the loop on the exact failing state. For a suspected regression, establish the other side with the parent, known-good commit, or a controlled ablation when this is feasible and authorized. A lone pass or failure does not attribute causality.

Reduce input, configuration, callers, and steps one variable at a time, keeping only elements that carry the failure. For timing-sensitive or nondeterministic bugs, prioritize a robust high-rate reproducer over the smallest one; use the minimal case later for explanation or handoff.

If only good and bad endpoints are known, offer to turn the feedback command into an automated range bisection. Start only with explicit Git-write authorization and confirmation for repeated long builds; isolate the run, record skipped commits, and leave bisect state only when the user wants it preserved.

Stay on a fixed experimental state while diagnosing. Do not pull, rebase, cherry-pick, or switch baselines mid-investigation unless deliberately creating an isolated comparison.

## 4. Rank hypotheses and probe them

For an ambiguous cause, write 3–5 ranked, falsifiable hypotheses before testing. Give each a prediction: “If X is causal, changing Y while holding the other variables fixed will change Z.”

Run the highest-information probe first. Prove the suspected path is exercised using IR, logs, counters, traces, or another direct artifact. Use a debugger only when stopping execution cannot erase the behavior. Tag temporary instrumentation with a unique marker such as `[DEBUG-a4f2]` so cleanup is mechanically verifiable.

## 5. Locate origin and manifestation

Name separately:

- **Source:** where the invalid state or behavior is created.
- **Site:** where it becomes visible as a crash, diagnostic, wrong value, or slowdown.

Trace the actual intermediate state between them. Compare a sibling backend, upstream path, or analogous component that is immune; determine the mechanism that makes it different rather than assuming equivalence.

## 6. Choose the fix layer

Enumerate plausible fixes at the source, an intermediate boundary, and the site. Compare blast radius, regression risk, ownership, and robustness. The deepest fix is not automatically the safest one; a narrow boundary guard may be the right immediate fix when a generic source change is risky. Record why the chosen layer wins and whether a deeper follow-up remains.

If the request was diagnosis-only, stop with the verified cause, evidence, candidate fix layers, and the recommended next action.

## 7. Fix and verify

When implementation is authorized:

1. Use `test-driven-change` to turn the reproducer into a failing test at a faithful seam, apply the minimal fix, and verify red-to-green with an independent oracle.
2. Rerun the original unreduced reproducer and the nearest affected sibling paths.

If `test-driven-change` finds no faithful test seam, carry that architectural finding into the handoff rather than adding false-confidence coverage.

## 8. Clean up and hand off

Remove all tagged instrumentation and throwaway harnesses unless the user wants a durable reproducer. Ask what condition allowed the bug—missing invariant, weak seam, absent validation, or misleading tool feedback—and record only a concrete preventive follow-up.

Use `pr-ready-self-review` for an implemented diff or `ship-external-artifact` for an upstream report/reproducer. Defer history surgery until the fix is verified and explicitly authorized.

## Completion check

- [ ] Current state and evidence freshness are pinned.
- [ ] One repeatable command detects the exact symptom.
- [ ] Regression causality is controlled, or the missing baseline is explicit.
- [ ] Source and manifestation are distinct and linked by evidence.
- [ ] Hypotheses were tested with one-variable probes when ambiguity required them.
- [ ] Fix layer was chosen deliberately; diagnosis-only scope was respected.
- [ ] Regression test and original reproducer pass after an authorized fix.
- [ ] Temporary instrumentation is gone and remaining risks are stated.
