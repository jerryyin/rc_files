---
name: investigate-dont-assert
description: >-
  Ground technical claims in the artifact that owns the truth, distinguish
  observation from inference, and show a concrete case. Use when explaining how
  something works, researching documentation or source, judging why a change is
  needed, debugging, reviewing, or validating a result. Other skills use this as
  their shared evidence discipline.
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

## When challenged

Return to the source or rerun the experiment before adding explanation. Update the hypothesis to fit the evidence. State plainly when access, cost, nondeterminism, or missing artifacts prevent confirmation.

## Completion check

- [ ] Each non-trivial claim points to the owning source or decisive artifact.
- [ ] Observed, inferred, and unknown are not blended.
- [ ] The example is both small enough to inspect and faithful enough to prove the claim.
- [ ] Causal comparisons hold other relevant variables fixed.
- [ ] Sensitive values are absent from quoted evidence.
