---
name: triton-mi450-perf
description: >-
  Methodology for performance investigation and optimization of gfx1250 (MI450)
  Triton / gluon kernels under the AM cycle-accurate simulator — localizing a
  specific instruction-level stall, fixing it, and validating it off-hardware so
  scarce B0 machine time only confirms an already-proven fix. Use when asked to
  profile, speed up, or relieve a stall/bottleneck in an MI450 kernel, especially
  when a B0/ATT trace points at a source line or wait opcode.
---

# triton-mi450 AM performance study

This skill is the **meta process**. Concrete commands, environment setup, the
exact tools, and every hard-won gotcha live in a reference README — read it when
you need specifics or a worked example:

> `~/scripts/triton/moe/am_perf/README.md` (tools + a fully worked example in the
> same folder). Treat it as the implementation manual for this skill.

Do **not** rederive the gotchas from scratch; consult that README. This file is
only the skeleton and the principles, which apply even as details drift.

## Mindset: investigate, don't assert

Every claim must be rooted in a measurement, not in reasoning about what *should*
be fast. You will be wrong about where time goes. Proceed **one iteration at a
time**, and let the simulator — not intuition — decide whether a change helped.
State what you measured, what you infer, and what is still unknown, separately.
A plausible explanation is a hypothesis until a trace confirms it.

## You need TWO harnesses, always

1. **Perf harness — AM, standalone kernel only.** Exercise *only* the kernel
   under study, nothing else (no routing, no reference compute, no surrounding
   pipeline). Anything extra pollutes the trace and the cycle count and makes the
   target impossible to isolate. This harness produces the timing/stall evidence.
2. **Correctness harness — FFM.** A separate harness that runs the same kernel
   against a reference and checks numerics. Use it to gate every kept change.

Keep these distinct. The perf harness optimizes for clean isolation and speed;
the correctness harness optimizes for a trustworthy reference. Don't conflate
"it ran" with "it's correct" — prove correctness on FFM.

## AM is slow — keep the harness SMALL

AM is cycle-accurate; cost scales with work simulated. The perf harness must be
the **smallest input that still exercises the code path** (smallest grid, fewest
tiles, shortest loop that still reproduces the stall). A too-large run wastes
hours and produces traces too big to analyze. Shrink the problem, not the
realism of the path. If you must scale up for realism, do it once at the end.

## The loop (this is the core of the skill)

Iterate this until the bottleneck is relieved. The loop matters more than any
single tool:

1. **Name the target.** From the HW/ATT trace (or a hypothesis), pin the exact
   source line + wait/opcode you think is the stall. Correlate it to the compiled
   assembly so you know what it really is and why it stalls.
2. **Baseline.** Run the perf harness under AM. Capture the trace.
3. **Measure two things:** (a) the kernel's own cycle count, and (b) the
   *targeted* stall specifically. Confirm the bottleneck is actually present and
   record both numbers. If the trace contradicts the hypothesis, update the
   hypothesis — don't proceed on the original story.
4. **One change.** Make a single, minimal edit motivated by the evidence.
5. **Re-measure.** Rerun the perf harness (force recompilation). Compare against
   baseline: did the targeted stall shrink? did the kernel regress? did anything
   else get worse (e.g. register pressure / spills)?
6. **Gate on correctness.** Run the correctness harness on FFM. A faster wrong
   kernel is not a fix.
7. **Keep or revert**, then repeat for the next change. Change one thing per
   iteration so each measurement attributes cleanly.

Only after the loop converges do you produce the diff as the deliverable.

## Judging a fix (and the simulator-vs-hardware gap)

Use two metrics together: **per-kernel cycles** (headline A/B number) and the
**targeted stall** (proves the specific bottleneck is gone). They can disagree —
removing a stall that was a small fraction of the kernel barely moves total
cycles. That is expected; judge primarily by the targeted stall going to ~zero
*and* no regression elsewhere.

Be aware the simulator's regime may differ from B0 hardware (occupancy, latency
hiding, tile count), so AM *proportions* won't match an ATT trace. The AM loop's
job is to prove a specific change removes a specific stall safely; the aggregate
hardware win is then confirmed on B0 — which, having done this work, costs one
run instead of many.

## Output

A minimal, reviewable kernel diff plus the before/after evidence (the two metrics
for baseline vs fixed, and the correctness result). Save worked examples next to
the reference README so the next investigation has a precedent.
