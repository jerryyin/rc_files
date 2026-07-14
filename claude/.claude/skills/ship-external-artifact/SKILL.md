---
name: ship-external-artifact
description: >-
  Package work into an artifact an outside, expert audience will scrutinize — a
  bug report, a standalone reproducer, an RFC, a public PR, a doc for review. Fix
  the target shape and audience up front so you converge by design, not by
  subtraction; strip investigation scaffolding; remove indirection; make the
  evidence complete and every claim defensible. Use on "package this for
  upstream", "write this up as an issue", "make this submittable", or before
  handing anything to people who do not share your context.
---

# Ship External Artifact

The work that found the answer is not the artifact that conveys it. An outside
reviewer shares none of your context, has little patience, and will dismiss the
whole thing over one falsifiable claim or one confusing indirection. Reshape the
output for *them*, in one deliberate pass — not by trimming over many rounds
after they push back.

Decide the destination shape **before** assembling. Most churn comes from
committing the investigation's byproducts and then converging by subtraction;
naming the audience and the minimal artifact first collapses that into one pass.

Compose with siblings: `investigate-dont-assert` for grounding every claim;
`pr-ready-self-review` for the code-level cleanup of any diff you include.

## 1 — Frame: audience and minimal artifact
Before touching files, write down: **who** reviews this and what they already
know; the **least** they need to act (the one input, the one command, the one
check); and the **voice** (a claim to be judged, not a tour of your journey).
e.g. "An <X> maintainer needs the input, the command, and a runnable check —
nothing else." This one decision is the target everything else is cut toward.

## 2 — Cut to the deliverable
Remove **investigation scaffolding** — the capture harness, the bisect log, the
intermediate variant, the dump you read once. This is real work, not junk, but it
is how you *found* it, not what the audience *needs*. A finding that mattered to
you becomes one sentence, not a file. (Sharper than hygiene: scaffolding is
correct and yours, and still must go.)

## 3 — Remove indirection
Fewest files, fewest hops to understand any one of them. Prefer embedded data over
a sidecar file, one entry point over several near-identical scripts, and names
that explain themselves over names that need the README. Every extra file or layer
is something the reviewer must hold in their head before they will trust you.

## 4 — Complete, self-checking, adversarial-proof evidence
- **Show A and not-A.** "X causes the failure" needs the control where X is absent
  and the failure is gone. One-sided evidence invites "did you rule out …?" — rule
  it out *in* the artifact.
- **Make it self-checking.** Prefer a result the reviewer can confirm without
  trusting your numbers: a differential, an exit code, a diff.
- **Audit every claim adversarially.** For each sentence a hostile expert could
  test: is it true, and does it survive the obvious counter? Cut or qualify the
  convenient axiom and the over-attributed cause. Preempt the first objection a
  reviewer will raise; if your own evidence contains the counterexample, address it
  before they find it.
- Verify, don't assert: every number and behavior reproduced, not remembered.
- **Run it as the reviewer will.** The artifact's own expected output is a claim:
  execute it on its *default* invocation, cold, the same N times a reviewer would.
  The default path must demonstrate the headline reliably; if the clean result
  only holds under special conditions, make the default show the claim that holds
  *every run* and label the conditional one — never print a header the run
  contradicts. Choose the control that is reliably clean, not the one you expect
  to be (the appealing baseline that occasionally fails is not a control).

## 5 — Package and hand off
- State the result as a claim with its evidence, not a narrative of the hunt.
- Include exactly the framed artifact set; describe each file in one line.
- If the cause lives in someone else's component, the deliverable is a minimal
  reproducer + report for *them* (plus, separately, a local workaround) — not a
  fix in your own tree.
- Run `pr-ready-self-review` on any code in the artifact before release.

## Anti-patterns
- **Converging by subtraction.** Shipping the investigation, then trimming it over
  many review rounds instead of framing the target first.
- **Scaffolding as deliverable.** Committing the capture/bisect/dump tooling
  because it is real and it is there.
- **Indirection tax.** Sidecar files and parallel scripts where embedding and one
  entry point would do.
- **One-sided evidence.** A cause with no control; "it is slow" with no baseline.
- **A convenient claim.** A clean-sounding assertion (an axiom, a single-number
  cause) a domain expert can falsify in one line.
- **Journey voice.** Narrating what you tried instead of stating what is true.

## Checklist
- [ ] Audience, minimal artifact, and voice named before assembling.
- [ ] Investigation scaffolding removed; findings demoted to sentences.
- [ ] Indirection minimized: fewest files/hops, embedded over sidecar, self-explaining names.
- [ ] Evidence shows A and not-A and is self-checking; control is the reliably-clean case.
- [ ] Artifact run on its default path, cold, N times; printed output matches the headline.
- [ ] Every claim verified and survives the obvious expert objection.
- [ ] Cross-boundary cause → upstream reproducer/report, not a local fix.
- [ ] Code passed `pr-ready-self-review`; artifact set listed and minimal.
