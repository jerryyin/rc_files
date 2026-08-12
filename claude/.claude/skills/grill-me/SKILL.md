---
name: grill-me
description: >-
  Stress-test a plan, design, or consequential decision through a focused
  interview. Use only when the user explicitly asks to be grilled, invokes
  grill-me, or requests an exhaustive challenge of their thinking before action.
  Resolves decision dependencies in rounds, investigates discoverable facts,
  recommends a position for every choice, and exposes material assumptions.
---

# Grill Me

Turn an underspecified idea into a shared, decision-complete understanding before implementation. Question the choices that can materially change the goal, architecture, scope, risk, or success criteria; skip preferences that can be decided cheaply during execution.

## Build the decision tree

1. State the apparent goal and intended outcome in one sentence.
2. List the unresolved decisions and their dependencies. A decision is blocked when its answer depends on another unresolved choice or a missing fact.
3. Separate facts from decisions. Investigate facts available from the workspace, source, documentation, tools, or delegated research. Ask the user only for judgments, priorities, authority, or unavailable context.
4. Identify the **frontier**: the highest-leverage decisions whose prerequisites are settled now.

## Interview in rounds

Ask the frontier in a compact round. For each question:

- Explain why the decision changes the result.
- Offer concrete, mutually exclusive options when useful.
- Give a recommended answer and its main trade-off.
- State the default you will carry forward if the user delegates the choice.

Do not ask a question whose answer depends on another question in the same round. Incorporate the user's answers, update the decision tree, investigate newly unblocked facts, and ask the next frontier. Challenge contradictions with earlier answers, repository constraints, or observed behavior directly.

Keep rounds small enough for thoughtful answers. Prefer a few load-bearing questions over an exhaustive questionnaire of incidental details.

## Converge

Stop when no unresolved decision can materially change the proposed work. Summarize:

- Goal and success criteria.
- Chosen approach and constraints.
- Consequential assumptions and risks.
- Explicitly deferred or out-of-scope decisions.
- Recommended next action.

Ask the user to confirm or correct this understanding before implementation. Do not treat silence as approval and do not begin consequential work from the grilling session alone.

## Completion check

- [ ] Discoverable facts were investigated rather than delegated to the user.
- [ ] Every question was currently unblocked and material to the outcome.
- [ ] Every choice included a recommendation or explicit default.
- [ ] Contradictions and hidden assumptions were surfaced.
- [ ] The final understanding names success, constraints, risks, and scope.
- [ ] The user confirmed the result before action began.
