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

## Make the Evidence Navigable (not just correct)

The rules above make you show and trace the IR; these make you locate and lay it
out so the reader can jump straight in.

- Persist every IR/asm dump you reason about to a file, and cite the exact
  `file:line` of each chunk (e.g. `asm/kernel.after.s:971`) — the reader must be
  able to jump to it. Ephemeral stdout dumps do not count.
- Present each comparison as a locatable chunk, not a paragraph or a bare count:
  (a) where — `file:line`, (b) the minimal snippet, (c) one line of *why*.
- Pair BEFORE/AFTER at the *same* anchor, and add a CONTRAST/control — the
  nearest case that behaves correctly (e.g. the sibling load that already
  scalarizes) — to isolate the one variable.
- When the artifact set is worth keeping, persist before/after IR+asm as files
  and emit a small guide (resolve line numbers with `grep -n`, print
  `file:line` + snippet + why) so the inspection is reproducible and navigable
  later — do not rely on the in-chat explanation alone.
- Close with a compact delta table: `metric | before | after`.
