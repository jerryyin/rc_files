---
name: context-briefing
description: >-
  Produce a ground-up explanation or evidence-backed verdict for one codebase
  spot, behavior, error, concept, or claim. Use when the user asks "explain
  this", "what is this doing", "I don't understand X", or "give me the context
  around Y"; also use when they challenge truth or causality with "is this
  true", "confirm/refute", "prove this", "I'm not convinced", "what changed and
  why", or "push this to assembly/runtime". Builds from source plus real
  artifacts so the user gets the full picture in one pass.
---

# Context Briefing

Explain one codebase spot, or confirm/refute one technical claim, in one pass.

Apply `investigate-dont-assert`: ground non-trivial claims in source or observed
artifacts, cite `file:line` for source claims, show concrete examples, and label
observed / inferred / unknown.

## Choose The Shape

- **Explanation**: the user asks what/how/why. Teach from zero context with
  progressive disclosure: essence -> surroundings -> mechanism -> exact lines ->
  traps and nuance.
- **Verdict**: the user asks whether a claim is true, asks to confirm/refute or
  prove something, says they are not convinced, asks what changed, or asks to
  push to a lower artifact. The first non-empty line must be `**Verdict**`.

Mode only changes the answer shape. The investigation discipline is the same.

## Workflow

1. **Pin the object**: name the exact spot, behavior, or claim; define terms the
   first time they appear.
2. **Map the path**: identify who produces the input, who consumes the output,
   and which neighboring code/state matters.
3. **Choose the decisive artifact**: test at the layer where the claim can fail.
   Source is not enough for claims about emitted code, runtime behavior,
   hardware behavior, APIs, performance, wire format, persisted data, or UI.
4. **Use the authoritative path**: prefer the real commit, command, input,
   binary, trace, response, or file over a proxy. Treat reimplementations and
   sibling cases as evidence only after checking fidelity.
5. **Show A/not-A when causal**: compare patch vs ablation, old vs new, enabled
   vs disabled, failing vs passing. If only one side is available, say so.
6. **Show the smallest real example**: quote the minimal IR/log/assembly/output,
   command, request/response, screenshot/DOM state, query result, or code excerpt
   that carries the claim.
7. **Explain the mechanism**: say what changed, what stayed invariant, and why
   the observed artifact follows from the code or system rule.
8. **Bound the result**: separate observed, inferred, and untested axes.
9. **Surface traps**: call out look-alikes, abstraction-level mistakes, no-ops
   with side effects, and other confusions likely to cause follow-up rounds.

## Output Shapes

For explanations:

```markdown
**Essence.** <plain-language what + why>
**Where it sits.** <pipeline/call path/lifecycle>

**How it works**
<mechanism, with a concrete example>

**Exact spot**
<file:line and the relevant before/after or input/output>

**Look-alikes & traps**
<nearby concepts that are easy to confuse>

**Nuance & why it matters**
<edge cases and connection to the user's goal>
```

For verdicts:

```markdown
**Verdict**
Confirmed / refuted / partially confirmed: <one-sentence answer with scope>.

**Evidence**
<test object, command/context, and pinned variables>
A / with change:
<minimal raw artifact>
B / without change:
<minimal raw artifact>
Delta:
<small table or bullet list>

**Mechanism**
<why the artifact follows from the code/dataflow; what changed and what stayed invariant>

**Scope**
Observed: ...
Inferred: ...
Unknown / not tested: ...
```

Use every verdict heading, even for short answers. If the claim is not causal,
replace A/B with the smallest decisive observation and say why that observation
is enough.

## Anti-Patterns

- Undefined jargon or assumed project knowledge.
- Explaining before locating the spot in the system.
- Paraphrasing what an artifact "would" show instead of showing it.
- Stopping above the layer the user is challenging.
- One-sided causal verdict with no limitation label.
- Using `Essence` / explanation shape for a confirm/refute prompt.
- Missing mechanism, scope, or look-alikes.
- Dumping logs without identifying the few lines that prove the point.

## Checklist

- [ ] Shape chosen from user intent; verdicts start with `**Verdict**`.
- [ ] Spot/claim pinned; terms defined on first use.
- [ ] Source claims cite `file:line`; observed claims include commands/artifacts.
- [ ] Decisive artifact is at the layer where the claim can fail.
- [ ] Causal claims show A/not-A or label the missing side.
- [ ] Mechanism names what changed and what stayed invariant.
- [ ] Scope separates observed, inferred, and unknown.
- [ ] Traps/look-alikes are called out when they are likely to confuse the user.
