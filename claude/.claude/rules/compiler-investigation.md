---
description: Compiler investigation and explanation for IREE, Triton, GPU codegen, CI failures, and performance — including walking through why a pass/transform fires or misfires across IR chains
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

## Trace the Mechanism, Don't Paraphrase It

- To explain why a transform fires or misfires, trace the data flow: follow the
  actual SSA values by their dump names, def-to-use, through each op — not an
  abstract description of the behavior.
- Replay the pass over that real IR: at each hop name the op it sees, the branch
  it takes, and why (which operand it follows, which predicate passes/fails). The
  reader should be able to re-run the pass in their head.
- Decompose the graph into the few chains that matter and name them (e.g. the
  value's producer chain vs. an interfering write chain). Most confusion is two
  chains conflated; separating them is usually the whole explanation.
- Localize a surprise to the exact construct responsible — a specific op,
  attribute, missing value, or interface result — never a vague "the pass is
  conservative." State the mechanism's reasoning at that point.
- Anchor which IR you're in (TTIR / TTGIR / LLVM / asm) and bridge levels when it
  helps — show the same entity in IR and in asm so the transform connects to its
  hardware effect.
- Prefer framing a fix as recovering information the analysis lacked over
  relaxing a check; say which invariant still holds.
- Spend the detail on the one non-obvious hop, not a uniform tour.

## Experiment Discipline

Before comparing compiler performance or correctness results, freeze the
experiment: branch/SHA, build directory, input, flags, baseline, variant,
metric, and sanity checks. If any dimension changes, do not compare the numbers
as the same run.

For AMD-specific lowering or scheduling work, compare against the corresponding
NVIDIA or upstream reference when it is relevant and readily available. Explain
what is shared, what diverges, and why.

To reset accumulated device state, power-cycle the board; idling does not. An idle
interval varies only time-since-work, and nothing relevant has a long time constant:
thermal relaxes in minutes, clock and power residency in seconds, while allocator,
driver and queue state do not decay with wall-clock at all. A long wait is therefore
redundant against the fast mechanisms and powerless against the cumulative ones. When
a hypothesis needs a clean device, take the reboot and pay its bring-up cost. To test
whether accumulated work is the cause, prefer a dose-response inside one boot —
measure, inject a described dose of work, measure again — over waiting.

## Make the Evidence Navigable (not just correct)

Locate and lay the evidence out so the reader can jump in — the rules above show
and trace the IR; these make it findable.

- Persist every IR/asm dump to a file and present each comparison as a locatable
  chunk — (a) `file:line`, (b) minimal snippet, (c) one line of *why* — not a
  paragraph or a bare count. Ephemeral stdout doesn't count.
- Pair BEFORE/AFTER at the *same* anchor, plus a CONTRAST/control (the nearest case
  that behaves correctly) to isolate the one variable.
- For a keeper artifact set, commit before/after IR+asm and a small guide that
  resolves line numbers (`grep -n`) into `file:line` + snippet + why — so the
  inspection is reproducible, not chat-bound.
- Diff *canonicalized* asm, not raw bytes: strip target metadata/comments and
  compare the histogram of the opcodes that matter, plus the normalized stream. A
  raw `md5` counts benign scheduler/reg-alloc churn as a real change, so
  "byte-identical" claims made without stripping are wrong.
- Close with a compact delta table: `metric | before | after`.
