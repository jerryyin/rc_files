---
name: hw-rtl-root-cause
description: >-
  Drive a suspected hardware/silicon miscompile — a numerically wrong or
  run-to-run nondeterministic GPU result whose IR, synchronization, and
  data-layout are provably correct — from symptom to the exact victim
  instruction, then confirm the mechanism with a zero-perturbation probe
  (a hardware chicken bit or the RTL). Use when an instruction produces a wrong
  result with correct inputs, when a result is nondeterministic only at high
  occupancy, or when "it's a backend bug" is the conclusion but the mechanism is
  unknown. Complements root-cause-debug (software layers); this one crosses ISA→RTL.
---

# Hardware / RTL Root-Cause

**Essence.** Some GPU "miscompiles" are silicon bugs: the machine executes correct
instructions incorrectly. This skill takes such a bug — output numerically wrong
or nondeterministic, yet the IR, the waits/barriers, and the data-mapping are all
provably correct — down to the **exact victim instruction** in software, then
hands the final *signal naming* to the only probes that disturb nothing.

Terms: **ISA** = the emitted instructions; **RTL** = the Verilog for the silicon
that runs them; **VGPR** = per-lane register; **VALU** = vector-ALU op (e.g.
`v_pk_mul_f32`); **MFMA** = matrix unit; **chicken bit** = a HW config bit that
disables one micro-optimization; **wave** = a lane group; multiple waves
**co-execute** on one SIMD.

## The one idea
You cannot *observe* a timing race without disturbing it. So don't try to watch
the wrong value appear — **narrow what must be true** until only one instruction
can be at fault, do that narrowing on the **most robust repro you have**, and
confirm the mechanism only with interventions that change **zero instructions and
zero occupancy**: a chicken bit or static RTL.

## The localization ladder
Each rung is a strictly smaller suspect. Do not stop early and infer the rest.
1. **Output** — magnitude (ULP?), determinism (distinct outputs / N runs), gating (occupancy).
2. **Instruction class** — which lowering flips it (e.g. wide read vs strided). A *correlation*, not the culprit.
3. **Victim instruction** — the first value that is wrong; found by capture on a robust repro.
4. **Operand vs result** — inputs correct but output wrong ⇒ a hardware read/exec fault, not codegen.
5. **RTL signal** — the mis-wired wire, found by grepping the module the pinpoint named.
6. **Chicken bit** — the config bit that disables the suspect feature; toggling it = confirmation.

## Principles (the distilled lessons)

**1. Narrow on the most robust repro, not the smallest.** A hyper-reduced repro is
ideal for reasoning and for the RTL owner, but its race is *fragile* — any added
instruction tips it below threshold and masks it. Isolation needs a repro robust
enough to keep racing *through* your instrumentation. Test robustness first: if it
survives many injected `v_nop`s it will survive a capture; if a couple of stores
kill it, it's the wrong substrate. Minimize only *after* isolating, for the handoff.

**2. Capture with a store, not a debugger.** To read an intermediate, add a minimal
**store** of the suspect operand/output to a scratch buffer (repurpose a spare
kernel pointer arg). A store's operand read goes through a different path than the
faulting VALU read, so it reports the *true* value. Never use a debugger for a
concurrency race: a breakpoint **halts the wave**, which removes the co-execution
that *is* the bug — you will only ever see the correct state. Debuggers are for
inspecting the golden value, not for catching the race.

**3. Instrumenting the exact victim can *move* it — but cross-run determinism
sidesteps that.** For a co-execution timing bug, an instruction's *timing is its
participation in the race*. A **self-consistency** check (does `product == captured
operands`? does this instruction's output match its own inputs?) is confounded twice:
it can mask the whole race (fragile repro) *or* relocate the one instruction you
measured so it goes clean while the race fires elsewhere (robust repro). Do **not**
rely on single-instruction self-consistency.

The escape is a different question: not "is this instruction self-consistent?" but
**"across runs, with deterministic kernel inputs, which captured intermediate is
*not* reproducible?"** Capture a broad set of intermediates (e.g. *every* MFMA's
output element[0]) and diff each one run-to-run. This works *because* it needs no
golden and tolerates relocation: **as long as the instrumented kernel still races
(check: its final output is still distinct across runs), the race is present in the
very binary you are measuring**, so "input X is bit-identical every run but value Y
varies" is a valid localization. This is what actually cracks it — it walked a real
attn kernel from "output races" → "only the 2nd-of-pair P@V MFMAs vary" → "the MFMA
is faithful (same inputs ⇒ same output), the `v_pk` accumulator feeding it varies"
→ "the `ds_read` feeding the `v_pk` is bit-deterministic, but the `v_pk` produced a
different output from bit-identical inputs on N threads" = the victim, oracle-free.
Software *can* pinpoint the victim instruction after all; it just cannot name the
silicon signal.

**4. "Correct inputs, wrong output" is the door to RTL.** The moment an instruction
is wrong with provably-correct inputs, stop reasoning about codegen/memory-model —
it is below the ISA. That is when to cross into the Verilog.

**5. Occupancy is a first-class variable.** Contention/co-execution bugs appear only
above an occupancy threshold that is *machine-specific*; re-derive it (sweep grid
until the baseline reliably races) and run every experiment above it. Below
threshold everything looks "fixed."

**6. Only zero-perturbation probes confirm the mechanism.** Naming the RTL signal, or
proving "it's this feature," requires changing nothing about the program or its
timing: the **chicken bit** (disables the HW feature, 0 instructions, 0 occupancy
change) or **static RTL**. A chicken-bit pass turns a hypothesis into a diagnosis.

**7. Narrowing enables RTL, not the reverse.** Handing raw RTL to an agent drowns it.
The instruction-level pinpoint tells you *which module* to read (here: the SP GPR
read interface). Narrow first, then read RTL, then confirm with the bit.

**8. Know the oracle-free ceiling — it's a handoff, not a failure.** Software alone
*reliably* gives: a reproduction (at high occupancy), **directional** evidence
(unit/phase, data-error-vs-rounding, occupancy gating, bit-exact alternate lowering
as control), and — via the cross-run determinism sweep (Principle 3) — the **exact
victim instruction and the triggering condition** (e.g. "2nd-of-pair MFMA reusing
srcA triggers; the co-executing `v_pk` is the victim; the `ds_read` is innocent").
What software **cannot** do is name the **silicon signal** (which mis-wired RTL net,
which cache-hit latch) — that needs the chicken bit / RTL. Deliver repro +
directional evidence + victim + trigger; the owner names the net. Do not undersell
this: a correct victim+trigger tells the RTL owner exactly which module to open.

**9. Don't trust asm A/B to prove a mechanism.** For a schedule-fragile race, any
edit — even a same-data register rename or a dead `v_mov` — reshuffles the schedule
and moves the race. Matched-perturbation controls measure scheduling luck, not the
mechanism. Use A/B only for coarse present/absent localization on a robust repro.

**10. Sweep before you dive; don't hand-pick "the suspect."** When more than one
site could be the culprit (multiple reads, multiple MFMAs), instrumenting *one*
plausible-looking site and finding it clean proves only that *that site* is
innocent — indistinguishable from having picked the wrong one, and it is not
evidence toward "impossible." Capture a cheap 1-value signature of **every**
candidate at once (e.g. `element[0]` of all 16 MFMA outputs) on the robust repro,
diff run-to-run, and let the sweep *name* the site — only then deep-dive that one
with the full operand+output capture. A guess-one-site-and-instrument approach,
repeated on failure by guessing a different single site, looks like progress but
is a linear search dressed up as insight; the sweep is the same cost as one guess
and removes the guessing. Corollary: **do not declare "software can't do this" from
a single failed probe.** Each false "impossible" in the worked contrast below came
from generalizing one failed (repro, site) combination — re-run the sweep on the
*robust* repro across *all* candidates before escalating to RTL/chicken-bit.

## Procedure
1. **Freeze a repro and find its occupancy threshold** (sweep grid; document it).
   Detect the race by hashing the whole output each run → distinct/N.
2. **Prove the software innocent**: a different lowering of the *identical* layout
   is bit-exact; adding maximal fences changes nothing; accumulation precision is
   fixed. Only then is it hardware.
3. **Pick the robust repro** (Principle 1). **If multiple sites could be the
   culprit, sweep all of them first** (Principle 10) with a cheap signature capture
   — do not hand-pick one. **Then pinpoint the victim** (Principles 2–3) at the
   named site: store-capture its full operand + output at high occupancy; read the
   operand-vs-output wrong-rate/identity asymmetry to find "correct inputs, wrong
   output."
4. **Cross into RTL** (Principle 7): grep the module the pinpoint named for the
   read-enable/select/suppression signals; trace the mis-wired one.
5. **Confirm with the chicken bit** (Principle 6): toggle it on the *un-instrumented*
   repro; if the race vanishes, the mechanism is proven.

## Worked contrast (the teaching payload)
gfx950 `ds_read_b64` nondeterminism, ±1 ULP, only at full occupancy. Same bug on
two repros:
- **micro-dot** (hyper-reduced): race died at *2 capture stores* → **not isolable**;
  useful only as the minimal artifact for the RTL owner.
- **attn** (real kernel): race robust (survived 16 `v_nop`s + capture stores).
  *Wrong turns first:* a workitem-indexed capture was polluted by cross-workgroup
  last-writer (the kernel uses `workgroup.id` — index captures by
  `workgroup.id*blockDim + workitem.id`), and a single-instruction self-consistency
  check (`product == value×scale`?) came back clean while the output raced — the
  measured `v_pk` had been *relocated* out of the window (Principle 3). *What worked:*
  the **cross-run determinism sweep**. Capture element[0] of all 16 MFMAs, diff
  run-to-run with the kernel still racing → only the three **2nd-of-pair P@V MFMAs
  (those reusing `srcA` = operand cache-hit) varied**; the tail pair reused srcA too
  but stayed clean (no co-executing victim). Then capture that racy MFMA's
  inputs+output → **MFMA is faithful** (0 threads with same-inputs/different-output);
  its **accumulator (`v_pk` output) is what varies**. Then capture that `v_pk`'s
  inputs+output → the **`ds_read` feeding it is bit-deterministic**, yet the `v_pk`
  produced a **different output from bit-identical inputs on 64 threads** = the victim.
Chain: *MFMA srcA cache-hit (trigger) → co-executing `v_pk` reads a stale operand
(victim) → MFMA faithfully propagates → error accumulates down the chain.* Software
nailed victim + trigger oracle-free; the **`SQ_CONFIG1` chicken bit + RTL** only had
to name the mis-wired suppression net. Note this refuted two attractive-but-wrong
framings on the way: "the `ds_read` is racy" (it's bit-deterministic) and "the MFMA
uses a cached old accumulator" (the MFMA is faithful; the `v_pk` is the victim).

## Checklist
- [ ] Repro fires reliably; occupancy threshold documented.
- [ ] Software proven innocent (layout, sync, precision).
- [ ] Isolation done on the **robust** repro, not the smallest.
- [ ] If >1 candidate site existed, swept **all** of them before instrumenting one.
- [ ] Victim instruction pinpointed via store-capture + rate asymmetry (correct in / wrong out).
- [ ] No "software can't do this" conclusion drawn from a single failed (repro, site) combination.
- [ ] RTL signal traced in the module the pinpoint named.
- [ ] Chicken bit toggled on the un-instrumented repro → race vanishes → confirmed.
