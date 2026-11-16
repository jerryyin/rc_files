---
name: context-briefing
description: >-
  Explain one codebase spot, behavior, error, concept, test, or design choice so a reader who does not share the project's vocabulary understands it in one pass, or deliver an evidence-backed verdict on one technical claim. Use when the user asks "explain this", "what is this doing", "walk me through", "I don't understand X", "give me the context around Y", or "why X instead of Y"; also use when they challenge truth or causality with "is this true", "confirm/refute", "prove this", "I'm not convinced", "what changed and why", or "push this to assembly/runtime".
---

# Context Briefing

An explanation succeeds when the reader needs no follow-up question to understand it. Follow-up rounds come from three gaps: the answer starts somewhere other than what the reader is looking at, it relies on a concept the reader was never given, or it spreads across code that does not decide the behavior. This workflow closes each gap before writing.

Apply `investigate-dont-assert` for every claim: it owns evidence, citation, and observed / inferred / unknown labels. This skill owns what to explain, in what order, and in what words.

## Workflow

1. **Anchor on the reader's artifact.** Identify the exact thing the reader is looking at (a line, test, output, error, diff, or term) and restate their question in their own words. Every identifier, expression, language or framework construct, and special value (zero, empty, a limit) in the part of the artifact the question touches will need a plain meaning in the answer. Done when you can quote that artifact and list those names and values.
2. **Trace to the decision site.** Follow the data or control from that artifact to the place where the behavior in question is actually decided. Keep only the hops that carry the value; name each with `file:line`. Done when every hop between the artifact and the decision is accounted for and nothing off the path is included.
3. **Build the prerequisite ladder.** List every concept the answer will use: domain ideas, hardware or platform facts, project terms, and how the code is run (launcher, process layout, environment, configuration). Count a concept as known only if the reader stated or demonstrated it; otherwise treat it as unknown. A project's own name or abbreviation for something the reader knows under another name is unknown until mapped to the reader's term. Order the unknowns so each relies only on earlier rungs or on known ground, and note for each what it does for this answer, not just what it is. Done when every term the answer needs is either known or on the ladder with its role.
4. **Gather the evidence** at the decision site and along the path, as `investigate-dont-assert` requires. State each claim only as strongly as the code read or the output observed supports it.
5. **Write in the chosen shape** (below). Teach the ladder before the mechanism, and follow one concrete instance with real values from the artifact to the decision. For each mechanism on the path, say what it is for; when it divides work, resources, or responsibility, say what every part does and what the division trades off.
6. **Reread as the reader.** Every term is defined before first use, in plain words. Every code citation is a decision site or a hop to it. No sentence depends on knowledge outside the ladder. Comparisons and conclusions match the evidence's strength. Then ask what this reader would ask next, and answer it or say why it is out of scope. Fix the draft until no next question remains that the answer should have settled.

## Choose the shape

- **Explanation**: the reader asks what, how, or why.
- **Comparison**: the reader asks why one choice was made over another. It is an explanation whose mechanism is the smallest model in which the alternatives behave differently.
- **Verdict**: the reader asks whether a claim is true, to confirm or refute it, says they are not convinced, asks what changed, or asks to go to a lower artifact. The first non-empty line is `**Verdict**`.

Mode changes only the answer's shape; the workflow above applies to all three.

### Explanation

```markdown
**Essence.** <written last: the answer in words the reader already has, claiming nothing the body does not establish; if that is impossible before the ladder, say what the answer will establish>

**What you need first**
<first, what each name, construct, and special value in the reader's artifact means; then the unknown rungs, bottom-up, each in one or two plain sentences saying what it is and why it matters here, with a concrete instance>

**Walk-through**
<one concrete instance followed from the reader's artifact to the decision, with real values at each hop>

**Where it is decided**
<file:line and the minimal excerpt for each decision site; how to find it (the search command), and why navigation tools cannot follow the path when they cannot>

**Look-alikes & traps**
<similar names, concepts, or layers likely to cause the next question>

**Limits**
<what is observed, inferred, or unknown; what this answer deliberately does not cover>
```

Omit **What you need first** only when the artifact's names are self-evident to the reader and the ladder has no unknown rungs.

### Comparison

Use the explanation shape. In **Walk-through**, build the smallest model in which the alternatives produce different outcomes, then show a table of what each alternative triggers along that axis and what each gives up. Argue only in terms the model introduced. If the alternatives differ less than the question assumes, say so first.

### Verdict

```markdown
**Verdict**
Confirmed / refuted / partially confirmed: <one-sentence answer with scope>.

**Evidence**
<test object, command or context, and pinned variables>
A / with change:
<minimal raw artifact>
B / without change:
<minimal raw artifact>
Delta:
<small table or bullet list>

**Mechanism**
<why the artifact follows from the code or data flow; what changed and what stayed invariant>

**Scope**
Observed: ...
Inferred: ...
Unknown / not tested: ...
```

Use every heading, even for short answers. If the claim is not causal, replace A/B with the smallest decisive observation and say why it is enough. When the reader lacks vocabulary the verdict depends on, add the ladder as a short primer under **Mechanism**.

## Scope

- Quote code only at decision sites and the hops that reach them. Mention other code by path, without explaining it.
- Stay at the layer the question lives at. Go lower only when the reader challenges that layer or the decision is made there.
- Prefer one complete, concrete instance over several partial ones.

## Completion check

- [ ] The answer starts from the reader's artifact and reaches the decision site.
- [ ] Every name, construct, and special value in the artifact that the question touches has a plain meaning in the answer.
- [ ] Every unknown concept is taught, in plain words and in dependency order, before it is used; project synonyms are mapped to the reader's terms.
- [ ] Each mechanism on the path states its purpose, and any division of work states what every part does.
- [ ] Code citations are limited to decision sites and the path to them, each with `file:line` and a way to find it.
- [ ] A comparison rests on a model where the alternatives actually differ.
- [ ] A verdict starts with `**Verdict**` and keeps every verdict heading.
- [ ] Claims carry the evidence and labels `investigate-dont-assert` requires, and none is stronger than its evidence.
- [ ] The Essence claims nothing the body does not establish.
- [ ] The reader's likely next question is answered or explicitly scoped out.
