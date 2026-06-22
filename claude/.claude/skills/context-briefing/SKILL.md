---
name: context-briefing
description: >-
  Produce a complete, ground-up explanation of one spot in a codebase — a
  function, pass, line, error, or concept the user points at — in a single pass.
  Use when the user wants to understand a specific place: "explain this", "what
  is this doing", "I don't understand X", "give me the context around Y". Builds
  from zero project knowledge up through the nuanced details, example-first, so a
  newcomer reaches full understanding without a second round.
---

# Context Briefing

Given one spot the user points at, produce the explanation you wish you'd had on
day one: starts from nothing assumed, leads with concrete examples, and layers
from the plain-language essence down to the exact line and its edge cases — all
in one pass.

Optimize for **completeness over brevity**. The reader skips what they already
know; they cannot conjure what you left out. Investigate thoroughly and populate
the whole picture in one go rather than handing back a thin answer they must
keep probing.

Apply `investigate-dont-assert`: every claim grounded in the code at `file:line`,
every non-trivial point carried by a real example, observed vs inferred labeled.

## The layering principle

A newcomer cannot absorb the exact detail until they have a place to put it.
Structure every briefing as **progressive disclosure** — each layer complete on
its own, so the reader stops the moment they are satisfied:

1. **Essence** — one or two sentences: what this is and why it exists, in plain
   language, no jargon undefined.
2. **Mechanism** — how it actually works, the moving parts, walked through.
3. **Exact spot** — the specific code/line, named precisely, tied to the mechanism.
4. **Nuance** — edge cases, gotchas, the gated branch, the look-alike trap, the
   "this is true except when…".

Lead with the essence. Detail before the big picture has nowhere to land.

## Procedure

1. **Pin the spot and assume zero context.** Identify exactly what the user
   pointed at. Define every term the first time it appears; do not assume project
   experience, conventions, or acronyms are known.
2. **Lead with the essence + a picture.** State the one-line what-and-why, then
   show where this spot sits — the pipeline stage, call path, or lifecycle around
   it. "Where am I and what touches this" is a newcomer's first question.
3. **Map the actors.** Name what produces the input, what consumes the output,
   and who else reads or writes the thing in question. Make the neighbors explicit.
4. **Make examples the backbone, not decoration.** For each idea, show the
   smallest real case: actual input/output, before/after state, the concrete value
   that triggers the behavior. Prefer dumping the real artifact over describing
   what you expect it to look like. If you can't produce an example, you don't yet
   understand it well enough to explain it.
5. **Layer down.** Walk essence → mechanism → exact spot → nuance, each section
   self-contained.
6. **Surface the look-alikes and traps.** Call out the near-identical things that
   mislead newcomers — two similarly named entities, a no-op that looks like real
   work, one abstraction level mistaken for another — and distinguish them
   side by side. These are where understanding breaks.
7. **Connect to the bigger why.** Tie the spot back to the issue or goal that
   prompted the question, and to any sibling/reference that illuminates it by
   contrast.

## Briefing shape

```
# <Spot> — what it is in one line

**Essence.** <plain-language what + why, terms defined>
**Where it sits.** <pipeline/call-path picture>

## How it works
<mechanism, walked through, with a concrete example at each step>

## The exact spot
<the specific code/line at file:line, tied to the mechanism>
<before -> after, or input -> output, shown literally>

## Look-alikes & traps
| this | vs that | how to tell them apart |
...

## Nuance & edge cases
<gated branches, exceptions, "true except when…">

## Why this matters here
<connection to the issue/goal; reference contrast if any>
```

## Anti-patterns
- **Assumed knowledge.** Undefined jargon, acronyms, or conventions a newcomer won't have.
- **Detail before picture.** Diving into the line before the reader knows what the thing is.
- **Example-free assertion.** A mechanism described but never shown on a real case.
- **Paraphrase over artifact.** Describing what the IR/output "would" be instead of dumping it.
- **Flat dump.** All depth at once, or all surface — no layering for the reader to navigate.
- **Stopping at the surface.** A thin answer that forces a second, third, fourth round of questions.
- **Skipping the look-alikes.** Leaving the exact confusions that trip newcomers unaddressed.

## Checklist
- [ ] Spot pinned; every term defined on first use; zero project knowledge assumed.
- [ ] Essence and "where it sits" lead, before any detail.
- [ ] Producers/consumers/neighbors named.
- [ ] Every non-trivial point carried by a concrete, minimal, real example.
- [ ] Layered essence → mechanism → exact spot → nuance, each self-contained.
- [ ] Look-alikes and traps distinguished side by side.
- [ ] Tied back to the prompting issue/goal; reference contrast if relevant.
- [ ] Complete in one pass — reader can skip, but nothing essential is missing.
