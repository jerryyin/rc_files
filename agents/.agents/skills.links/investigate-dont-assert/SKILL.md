---
name: investigate-dont-assert
description: >-
  Ground technical claims in the artifact that owns the truth, distinguish
  observation from inference, and show a concrete case. Use when explaining how
  something works, researching documentation or source, judging why a change is
  needed, debugging, reviewing, or validating a result. Also use before accepting
  a conclusion, to derive the test that would falsify it. Other skills use this
  as their shared evidence discipline.
---

# Investigate, Don't Assert

An unchecked claim is a hypothesis. Match each claim to evidence at the layer where it could be false.

## Ground claims at their source

- For local code, read the mechanism and cite `file:line`.
- For external facts, follow the claim to the owning primary source: official source, specification, documentation, commit, or first-party issue discussion. Cite it next to the claim.
- For runtime, performance, emitted-code, wire-format, persisted-data, or UI behavior, capture the real output. Source intent alone cannot prove an observed result.
- Prefer the exact input, commit, binary, request, trace, or configuration over a reimplementation or sibling case. Treat proxies as hypotheses until fidelity is checked.
- Redact secrets and sensitive payloads before showing commands or artifacts; keep credentials in their secure source or environment.

Use evidence proportionate to the claim. A local naming fact may need one source line; a causal or general claim needs a controlled comparison and coverage across the axes it names.

## Label epistemic state

- **Observed:** directly read or run, with the source, command, or artifact named.
- **Inferred:** a hypothesis that follows from observations but has not been directly tested.
- **Unknown:** a gap that available evidence does not settle.

Never promote an inference because it sounds plausible or a nearby run passed.

## Show a decisive case

Produce the smallest faithful example that carries the claim. For behavior, show an accepted and rejected case when useful. For causality, change one variable and show A/not-A. If a minimal case loses the phenomenon, keep the robust reproducer and explain why.

## Try to break it before accepting it

A conclusion nothing has attacked is still a hypothesis, however well evidenced. You cannot predict the specific failure, but conclusions fail in a small number of generic ways. Before accepting one, take each family below and try to instantiate it against what you have; every one you can turn into a concrete test is a test to run. The sections above already cover four — confounded comparison, proxy standing in for the real artifact, one case generalized to a class, one-sided causal evidence. The rest:

- **Alternative cause.** Attributed to X without ruling out Y. Design the test that separates them, not another test consistent with both.
- **Measurement validity.** The metric may not measure the claim. Re-derive it from the raw data — total versus in-loop, warm versus cold.
- **Mechanism grounding.** Behavior established, mechanism not. Trace the data flow or dump the intermediate form. A real mechanism predicts the next case; a correlation does not.
- **Intervention too small to show the effect.** A null result from a minimal intervention is not a null result for the hypothesis. Apply the intervention in its broadest sound form first, confirm an effect exists at all, then narrow to the minimal cause.

A claim that cannot be given a runnable test that would falsify it is not a conclusion yet.

## When challenged

Return to the source or rerun the experiment before adding explanation. Update the hypothesis to fit the evidence. State plainly when access, cost, nondeterminism, or missing artifacts prevent confirmation.

## Completion check

- [ ] Each non-trivial claim points to the owning source or decisive artifact.
- [ ] Observed, inferred, and unknown are not blended.
- [ ] The example is both small enough to inspect and faithful enough to prove the claim.
- [ ] Causal comparisons hold other relevant variables fixed.
- [ ] Each accepted conclusion carries a test that was run and could have falsified it.
- [ ] Sensitive values are absent from quoted evidence.
