---
description: Architecture-first reasoning before implementing non-trivial code changes or PRs — changes to APIs, IR, types, interfaces, compiler passes, data models, or shared abstractions with cross-component impact. Explore the problem, invariants, abstraction boundaries, consumers, representation choices, alternatives, and blast radius before proposing implementation; do not modify code during this phase.
---

# Architecture First

Before implementation, solve the design problem first.

## Workflow

1. **Define the problem**
   - State the concrete behavior that needs to change.
   - Separate the actual requirement from the proposed implementation.

2. **State the invariants**
   - What must be true before and after the change?
   - Identify semantic guarantees, not implementation details.

3. **Find the owning abstraction**
   - Determine which layer should own the new behavior.
   - Distinguish logical semantics from physical representation.
   - Avoid coupling a higher-level abstraction to a lower-level encoding just because it is convenient.

4. **Map consumers**
   - Find creators, readers, transformers, converters, serializers/parsers, optimizations, backends, and tests.
   - Pay special attention to code that reconstructs, copies, or assumes the representation.

5. **Explore alternatives**
   - Identify 2–3 viable designs when the choice is non-obvious.
   - For each, state the key tradeoff: correctness, scope, compatibility, complexity, performance, or maintainability.

6. **Check the blast radius**
   - Ask what other subsystem, backend, consumer, or invariant could be affected.
   - Generate a few adversarial cases and edge cases before choosing a design.

7. **Choose the minimal sound change**
   - Separate the ideal long-term architecture from the smallest safe change that solves the current problem.
   - Explicitly list what should *not* be changed in this PR.
   - Identify worthwhile follow-ups rather than expanding scope unnecessarily.

## Output

Produce a concise architecture brief:

```text
Problem:
Invariant:
Owning abstraction:
Key consumers:
Design options:
Tradeoffs:
Chosen design:
Blast radius / risks:
Non-goals:
Follow-ups:
```

Keep it concrete and repository-specific. Prefer evidence from the codebase over assumptions.

## Hard Rule

**Do not edit or implement code while doing architecture-first analysis.**

If the design is still ambiguous, investigate the repository further rather than prematurely coding.

The goal is to catch:

- wrong abstraction boundaries
- accidental representation coupling
- hidden consumers
- cross-backend regressions
- unnecessary scope
- designs that solve the local symptom but weaken the architecture
