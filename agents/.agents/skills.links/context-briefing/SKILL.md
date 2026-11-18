---
name: context-briefing
description: >-
  Explain one codebase spot, behavior, error, concept, test, design choice, or how several pieces fit together and when each runs, so a reader who does not share the project's vocabulary understands it in one pass, or deliver an evidence-backed verdict on one technical claim. Use when the user asks "explain this", "what is this doing", "walk me through", "how does this fit together", "I don't understand X", "give me the context around Y", or "why X instead of Y"; also use when they challenge truth or causality with "is this true", "confirm/refute", "prove this", "I'm not convinced", "what changed and why", or "push this to assembly/runtime".
---

# Context Briefing

An explanation succeeds when a first-time reader can follow it in one pass and needs no follow-up question. Two things break that: detail arriving before the reader has a frame to hang it on, and a frame that never reaches what the reader actually asked. So build the frame first, the flow of the code at the level of its main functions, then go exactly as deep as the question needs.

Apply `investigate-dont-assert` for every claim: it owns evidence and citation. Label an inferred or unverified claim where it is made, `(inferred)`, rather than in a separate section. This skill owns what to explain, in what order, and at what depth.

## Workflow

1. **Anchor on the question.** Restate it in the reader's words and note any specific thing it names: a line, a value, a behavior, a claim. Done when you know what the direct answer must reach.
2. **Map the flow.** Split the behavior into phases by when they run (process start, per request, per call, at capture versus replay, ...). For each phase pick its one main function: the function the surrounding system calls into for that phase, not the deepest interesting one. Done when the reader could narrate the phases in order from the list alone.
3. **Find each main function's decisions.** List the choices it makes at its own level, as a short list rather than nested steps, and name the callees it hands off to. Step into a callee only when it makes a decision the question is about, or one without which the phase cannot be understood. Done when every phase has its decisions and nothing below that level appears without that reason.
4. **Pick the terms.** Keep only the terms needed to read the summary and the flow, each in a sentence or two of plain words without code citations; map project names to the reader's own terms. Define anything else in place, at first use.
5. **Gather the evidence** for each decision and for the direct answer.
6. **Write in the shape below.** Cite `file:line` once per phase, at its main function, and at the code that decides the direct answer; name every other function without a location. Follow one concrete instance through the phases, giving its real values at the decisions only; derive or tabulate beyond it only when asked.
7. **Reread as a first-time reader.** Every paragraph adds one level of detail at most beyond what came before it. If the question named something specific, the answer reaches it directly and fully. Then name what the reader would likely want next and offer it, instead of writing it unasked.

## Shape

```markdown
<summary: at most four sentences: the phases in order, what each does, and the direct answer when the question asked for one>

**Terms**
<only those needed to read the summary and the flow>

**<Phase>: <when it runs>**
<its main function, `file:line`; what it does and the decisions it makes, at its own level; the callee walked through only when it makes a decision the question is about>

<one block per phase>

**<The reader's question, in their words>**
<when the question named a specific line, value, or behavior: the direct answer, going as deep as it needs, with `file:line` at the deciding code; add to the summary rather than repeat it>

**Going deeper**
<one or two lines naming what can be expanded on request, and how to find it when navigation tools cannot follow the path>
```

The flow orients the reader; it never replaces the direct answer. Omit the question block only when the flow itself is the answer, and **Terms** when the reader already has them.

### Comparison

When the reader asks why one choice was made over another, build the smallest model in which the alternatives produce different outcomes, then show a table of what each alternative triggers along that axis and what each gives up. Argue only in terms the model introduced. If the alternatives differ less than the question assumes, say so first.

### Verdict

When the reader asks whether a claim is true, to confirm or refute it, says they are not convinced, asks what changed, or asks to go to a lower artifact, lead with the verdict:

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

If the claim is not causal, replace A/B with the smallest decisive observation and say why it is enough. When the reader lacks the vocabulary or the flow the verdict depends on, put a short summary and flow under **Mechanism**.

## Completion check

- [ ] The summary alone gives the phases in order and, when one was asked for, the direct answer.
- [ ] Each phase names its main function with `file:line` and says when it runs; other functions appear by name only.
- [ ] Nothing below a main function's level appears unless it makes a decision the question is about.
- [ ] A specific question gets its direct, complete answer; the flow does not stand in for it.
- [ ] Every term is in plain words, defined before or at first use.
- [ ] Inferred claims are labeled where they are made, and none is stronger than its evidence.
- [ ] The likely next question is offered, not written out unasked.
