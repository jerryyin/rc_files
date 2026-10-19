# Compiler Investigation

Applies when: Investigating or explaining IREE, Triton, GPU code generation, compiler CI failures, or compiler correctness/performance. Run hardware and Linux-specific commands on the configured execution host.

Apply [investigate-dont-assert](~/.agents/skills/investigate-dont-assert/SKILL.md) for technical evidence and explanations. For bugs, failing tests, or regressions, also follow [root-cause-debug](~/.agents/skills/root-cause-debug/SKILL.md).

## Concrete Compiler Evidence

- For compiler bugs, first prove whether the failing test exercises the changed
  code path. Use IR, logs, or targeted counters rather than intent.
- For transformations, show a concrete before/intermediate/after IR sketch
  before generalizing.
- When the user asks what a pass produces, prefer dumping the actual IR over
  paraphrasing it.
- For hardware-level explanations, name the level being discussed: workgroup,
  warp, lane, register, LDS, global memory, runtime, or driver.

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

## Experiment Discipline

On a shared machine, queue for the device lock — never poll it. Give the launcher
a blocking wait (`flock -w`, or whatever flag it exposes) and let it take its turn.
Retrying a refusal in a loop loses every race to whoever is already waiting, and it
reports a neighbour's normal turn as contention. Check the launcher's default before
assuming it queues: a non-blocking default is common, and a busy lock then reads as
a hard failure when it is only a wait. A held lock is not a fault to escalate.

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

## IR and Assembly Artifacts

- Persist before/after IR and assembly dumps to files at matching anchors. Include a small guide with `file:line`, a minimal snippet, and an explanation for each comparison.
- Diff *canonicalized* asm, not raw bytes: strip target metadata/comments and
  compare the histogram of the opcodes that matter, plus the normalized stream. A
  raw `md5` counts benign scheduler/reg-alloc churn as a real change, so
  "byte-identical" claims made without stripping are wrong.
