---
name: investigate-dont-assert
description: >-
  Cross-cutting evidence discipline for any technical claim: confirm against the
  code, separate what is known from what is guessed, and back every non-trivial
  statement with a concrete example. Use whenever you are about to assert how
  something works, why a change is needed, or what a system does — especially
  during debugging, code review, or self-review. Other skills lean on this one.
---

# Investigate, Don't Assert

A claim you have not checked is a guess wearing a fact's clothes. Before you state
how something works — or why a change is needed — ground it.

This is a shared primitive. `root-cause-debug` and `pr-ready-self-review` both
depend on it; apply it throughout either.

## The three rules

### 1 — Confirm against the source
Every "this is for X", "this handles Y", "this is safe because Z" must be checked
against the actual code, and cited as `file:line`. If you cannot point to the
line that makes it true, you do not yet know it is true. Prefer reading the
mechanism over paraphrasing intent; prefer dumping the actual output over
describing what you expect it to be.

### 2 — Separate observed, inferred, and unknown
State which is which, explicitly. An observation is something you ran or read. An
inference is a hypothesis built on observations. An unknown is a gap. Do not let
an inference graduate into an observation because it sounds right or because a
related run passed — a passing run nearby is a clue, not a proof.

### 3 — Back it with a concrete example
For any non-trivial claim, produce a real, minimal case: the input that triggers
the behavior, one case it accepts, one it rejects. If you cannot construct an
example — ideally the smallest one that still exhibits the behavior — treat the
claim as suspect and keep digging.

## When challenged
Re-check the evidence; do not elaborate the original story. If the user questions
an assumption, the correct first move is to go back to the code or rerun the
experiment, not to add reasons defending what you already said. Update the
hypothesis to fit the evidence, not the evidence to fit the hypothesis.

## Anti-patterns
- **Confident paraphrase of unread code.** "It probably does X" stated as "it does X".
- **Borrowed certainty.** Concluding from a passing adjacent run instead of the path in question.
- **Unlabeled inference.** Presenting a hypothesis with no marker that it is one.
- **Example-free claim.** A general statement with no concrete case behind it.
- **Doubling down.** Answering a challenge with more argument rather than more evidence.

## Checklist
- [ ] Every "this is for/does/handles X" cited to `file:line`.
- [ ] Observed / inferred / unknown labeled, not blended.
- [ ] Each non-trivial claim has a concrete, minimal example.
- [ ] Conclusions trace to the actual path, not a nearby passing one.
- [ ] On challenge, re-checked evidence before adding reasoning.
