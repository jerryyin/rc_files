---
name: investigation-loop
description: >-
  Drive an autonomous, self-pacing investigation to its real depth/breadth
  instead of a linear plan that stops at the first plausible conclusion. Run one
  decisive experiment + one adversarial refutation per iteration against a
  hypothesis ledger, iterating inline (blocking on builds) in one flow, and stop
  ONLY when every headline claim has survived a refutation test the loop derived. Use for overnight/long
  autonomous debugging, benchmarking, compiler root-cause, or reproduction work —
  anything where "just do 1,2,3" would accept a wrong answer. Compose with
  investigate-dont-assert, root-cause-debug, ship-external-artifact,
  compiler-investigation. Launch with /investigation-loop; span turns only when a
  turn can't hold the run or to poll untrackable external state.
---

# Investigation Loop

A linear plan ("do 1, 2, 3, report") accepts the first plausible conclusion. This
skill replaces the plan with a **refutation loop**: each iteration attacks the
current belief, and the loop only terminates when the surviving claims cannot be
falsified in one line. It exists because a plausible-but-wrong conclusion is the
default failure mode of autonomous work, and the fixes are cheap disciplines
applied *every* iteration, not once at the end.

## The ledger (single source of truth)

Maintain one markdown file, `investigation-ledger.md`, read at the start and
written at the end of every iteration. Never keep state only in your head.

```markdown
# <task> — ledger
## Goal & done-claims  (human writes the CLAIM; the loop DERIVES the test)
- CLAIM-1: <falsifiable statement>  | refutation test: <loop fills from Refutation schemas> | status: unchecked|survived|REFUTED
- ...  (DONE = every claim status == survived)
## Established facts  (each with HOW verified, not "I recall")
## Hypotheses
- H1: <statement> | status: open|supported|refuted | decisive experiment: <holds ONE variable> | evidence:
## Variables in play  (the axes any comparison must hold fixed)
## Next decisive experiment  (the single highest-information action)
## Dead ends  (so you don't re-run them)
```

## Iteration protocol (the loop body)

1. **Read the ledger.** Pick the ONE action that would most change current
   beliefs — usually the decisive experiment for the top open/most-load-bearing
   claim, not the easiest task.
2. **Freeze the experiment** (compiler-investigation "Experiment Discipline"):
   list every variable — commit/SHA, toolchain pin, inputs, flags, kernel/config,
   *your re-implementation vs the real artifact* — and change **exactly one**. If a
   comparison changes two, it proves nothing; redesign it.
3. **Prefer ground truth over re-implementation.** When reproducing someone's
   result, use *their* exact artifact (patch, commit, IR, binary) before deciding a
   discrepancy is real. A re-implementation that "should be equivalent" is a
   hypothesis, not a control.
4. **Run it.** Verify, don't assert — every number reproduced now, not remembered.
5. **Adversarially refute** (investigate-dont-assert / ship-external-artifact):
   you do NOT need to have predicted the failure mode. Walk the **Refutation
   schemas** below against the current claim; each schema you can instantiate from
   the ledger's "Variables in play" becomes a concrete test — run it. A conclusion
   is accepted only after the applicable schemas have been instantiated and passed.
6. **Update the ledger.** Mark hypotheses supported/refuted; append facts with how
   verified; record dead ends; set the next decisive experiment.
7. **Breadth gate before concluding:** enumerate the axes the claim ranges over
   (phase, kernel, dtype, size, target) and confirm it on *all* of them, not the
   one you happened to test. If an axis is untested, that's the next experiment.
   For genuinely independent hypotheses, fan out (background Agents / Workflow)
   rather than serializing.
8. **Terminate or continue — inline by default.** If every done-claim is
   `survived`, stop and write the result (hand to ship-external-artifact).
   Otherwise **loop back to step 1 in the same turn** and run the next iteration
   now. Iterations usually depend on the previous result (often a build), so
   **block and wait** rather than yield: run each experiment synchronously —
   foreground `Bash` if it fits the timeout, else `run_in_background` + a blocking
   `TaskOutput` — then continue. Do **not** background-and-yield or schedule a
   timer between dependent rounds; that only fragments the investigation. End on
   done, or when the ledger shows no runnable decisive experiment left (report the
   blocker + what artifact/access would unblock it — do not invent a conclusion).
   Only spill across turns when a turn genuinely can't hold the run (context/cost)
   or you're polling external state the harness can't track — see Pacing.

## Refutation schemas (the loop generates the test; you don't predict it)

You cannot predict the specific failure upfront. But conclusions fail in a small
set of generic ways. Each iteration, take the current claim and try to instantiate
each schema from the ledger's "Variables in play" / current state; every one you
can instantiate is a concrete test to run. The specific test *emerges* from the
schema + what you've discovered — it does not need to be foreseen.

- **Confound / isolation** — did the comparison change more than one variable?
  List every variable (commit, toolchain pin, input, flags, config/phase, your
  re-impl vs the real artifact); redo holding all but one fixed.
- **Artifact fidelity** — is this my proxy/re-implementation instead of the
  authoritative artifact (their patch, commit, binary, data, IR)? Use the real one
  before calling a discrepancy real.
- **Coverage / generalization** — did I verify one case and claim the class?
  Enumerate the axes (phase, size, dtype, target, input distribution); test the
  untested ones.
- **Alternative cause** — did I attribute to X without ruling out Y? Design a test
  that distinguishes them.
- **Measurement validity** — does the metric actually measure the claim? Re-derive
  from raw (e.g. total vs in-loop count, warm vs cold).
- **Mechanism grounding** — do I have behavior but not the mechanism? Trace the
  actual data flow / dump the IR; a real mechanism predicts the next case.
- **Boundary (A and not-A)** — remove the claimed cause: does the effect vanish?
  Add it back: does it return? One-sided evidence isn't a cause.

Extend this list when a new failure family bites (hand to rule-skill-upkeep).

## Stop condition (why this loop ends well)

DONE ≠ "ran N iterations" and ≠ "have a plausible story." DONE = **each headline
claim carries a refutation test that was executed and passed.** Examples of the
tests this forces (from real misses): "same input through both toolchain pins →
same output" (kills a mis-attributed regression); "used the upstream artifact, not
my port" (kills a false discrepancy); "holds on decode as well as prefill" (kills
an over-generalized fix). If a claim can't be given a runnable refutation test,
it isn't a conclusion yet.

## Anti-patterns (each one cost a manual round on #1885)

- **Attribute-then-move-on.** Blaming a component after comparing two things that
  differ in more than one variable. Freeze first.
- **Re-implement-then-conclude.** Treating your rewrite as the reference and
  declaring the original's result unreproducible. Get the real artifact.
- **First-plausible-stop.** Accepting "no fix exists / it's inherent" without a
  refutation attempt. Attack it.
- **Test-one-generalize-all.** Verifying on one case and claiming the class.
- **Flip-flopping.** Successive contradictory conclusions across rounds = the loop
  is skipping step 5; the ledger's refutation tests prevent it.

## Launch

```
/investigation-loop <goal + what "correct/done" looks like (falsifiable claims)>
```
You supply the **goal and acceptance** only — NOT the refutation tests; the loop
derives those each iteration from the Refutation schemas applied to what it has
discovered (table above). First iteration: create `investigation-ledger.md` from
the goal (Goal & done-claims, Variables, first decisive experiment), then run the
protocol, **iterating inline in one continuous flow** until the done-claims survive.

> **Do NOT launch inline work via `/loop`.** That slash command is cron-backed: it
> `CronCreate`s a fixed-interval timer *before* this skill runs and keeps firing on
> the clock regardless of the "inline" guidance here — a skill cannot un-schedule
> it. Use `/investigation-loop` for inline; use `/loop` only when you deliberately
> want the cross-turn timer (see Pacing).

## Pacing — inline by default; span turns only when forced

The iterations are a dependency chain (build → use its result → next experiment →
next build), so run them **inline, blocking on each step**, in a single flow. Do
not put a timer between rounds and do not background-and-yield a step whose result
the next round needs — that only fragments the investigation. Concretely:

- **Fast step:** run it foreground.
- **Slow step (build/subagent):** still inline — `run_in_background` then a
  **blocking** `TaskOutput` (or foreground `Bash` if it fits the timeout). You wait
  in the same turn; you don't hand control back mid-chain.
- **Cross-turn loop (`/loop` cron, or the `ScheduleWakeup` dynamic runtime):** only
  when a single turn genuinely can't hold the run (context/cost budget) or you must
  **poll external state the harness can't track** (remote CI, a deploy). The ledger
  carries state across fires. Note the mechanics we verified: `ScheduleWakeup` only
  fires inside the dynamic `/loop` runtime; the cron `/loop` slash command is a
  fixed-interval timer (no completion sense) — reserve it for external polling, not
  for chaining dependent build rounds.
- **Harness auto-wake:** if you *do* background truly independent long work, the
  harness re-invokes you on its completion — no polling timer needed.

State lives in the ledger, so if a run is interrupted or spans turns it resumes
cleanly.

The quality ceiling is the **falsifiability of the claims you state** — not
whether you can foresee how they break. "Figure out X" makes the loop wander; a
crisp falsifiable claim ("X is a regression", "the fix reaches 0") makes it
converge, because the loop can then aim the Refutation schemas at it. You state
*what would be true if you're right*; the loop works out *how to try to break it*.
