---
description: Shared compiler investigation workflow for IREE, Triton, GPU codegen, CI failures, and performance analysis
---

# Compiler Investigation

## Evidence Before Conclusion

- Separate observations from hypotheses. State what is known, what is inferred,
  and what remains unknown.
- Do not explain a failure from a passing local run alone. Passing locally is a
  clue, not a root cause.
- For compiler bugs, first prove whether the failing test exercises the changed
  code path. Use IR, logs, or targeted counters rather than intent.
- When the user challenges an assumption, re-check the evidence and update the
  hypothesis instead of elaborating the original explanation.

## Concrete Compiler Evidence

- For transformations, show a concrete before/intermediate/after IR sketch
  before generalizing.
- When the user asks what a pass produces, prefer dumping the actual IR over
  paraphrasing it.
- For hardware-level explanations, name the level being discussed: workgroup,
  warp, lane, register, LDS, global memory, runtime, or driver.
- Keep examples minimal. Strip boilerplate unless it changes the behavior under
  discussion.

## Experiment Discipline

Before comparing compiler performance or correctness results, freeze the
experiment: branch/SHA, build directory, input, flags, baseline, variant,
metric, and sanity checks. If any dimension changes, do not compare the numbers
as the same run.

For AMD-specific lowering or scheduling work, compare against the corresponding
NVIDIA or upstream reference when it is relevant and readily available. Explain
what is shared, what diverges, and why.
